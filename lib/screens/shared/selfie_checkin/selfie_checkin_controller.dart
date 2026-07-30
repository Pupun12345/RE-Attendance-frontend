import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/utils/constants.dart';

import '../login/login_view.dart'; // 👈 apna login view import karo
import '../selfie_camera/front_camera_capture_view.dart';

class SelfieCheckInController extends GetxController {
  final Color themeBlue = const Color(0xFF0B3B8C);

  final dateTime = ''.obs;
  final location = 'Fetching location...'.obs;
  final coordsText = 'Fetching coordinates...'.obs;
  final selfieImage = Rxn<File>();
  final isLoading = false.obs;

  String _fullAddress = '';
  Position? _currentPosition;
  // .obs so the "Employee" label updates once _loadUserData() resolves -
  // it's read from SharedPreferences asynchronously, so the very first
  // build always happens before it's ready.
  final userName = 'Loading...'.obs;

  Timer? _dateTimer;

  @override
  void onInit() {
    super.onInit();
    _startDateTimer();
    _fetchLocation();
    _loadUserData();
  }

  @override
  void onClose() {
    _dateTimer?.cancel();
    super.onClose();
  }

  void _startDateTimer() {
    _dateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final months = [
        "Jan","Feb","Mar","Apr","May","Jun",
        "Jul","Aug","Sep","Oct","Nov","Dec"
      ];
      int hour = now.hour;
      String ampm = hour >= 12 ? "PM" : "AM";
      hour = hour % 12 == 0 ? 12 : hour % 12;
      final time =
          "$hour:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} $ampm";
      dateTime.value =
      "${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year} $time";
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userName.value = prefs.getString('userName') ?? 'Unknown';
  }

  // Shares one in-flight GPS request instead of starting another every
  // time this is called, so tapping check-in while the initial fetch is
  // still running just waits on that one.
  Future<bool>? _locationFetch;

  Future<bool> _ensureLocation() {
    return _locationFetch ??=
        _fetchLocation().whenComplete(() => _locationFetch = null);
  }

  Future<bool> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      location.value = "Location services disabled";
      coordsText.value = "Enable GPS";
      return false;
    }

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever ||
        p == LocationPermission.denied) {
      location.value = "Location permission denied";
      coordsText.value = "Allow location access";
      return false;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPosition = pos;
      // Coordinates alone are a valid location. Seed the address with them
      // up front so a failed/empty reverse-geocode can never leave us with
      // nothing and block check-in.
      _fullAddress = "${pos.latitude},${pos.longitude}";
      coordsText.value =
      "Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}";

      // Reverse-geocoding needs internet even though GPS itself doesn't.
      // Keep this in its own try/catch so a network failure here doesn't
      // wipe out the GPS fix we already have or block check-in - fall back
      // to raw coordinates as the address instead.
      try {
        List<Placemark> places =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (places.isNotEmpty) {
          Placemark place = places.first;
          List<String> parts = [];
          if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
          if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
          if (place.subAdministrativeArea?.isNotEmpty == true) {
            parts.add(place.subAdministrativeArea!);
          }
          if (place.administrativeArea?.isNotEmpty == true) {
            parts.add(place.administrativeArea!);
          }
          if (place.postalCode?.isNotEmpty == true) parts.add(place.postalCode!);
          if (place.country?.isNotEmpty == true) parts.add(place.country!);

          _fullAddress = parts.join(", ");
          location.value =
          "${place.locality ?? "Unknown"}, ${place.subLocality ?? ""}";
        }
      } catch (_) {
        location.value = "No internet - showing GPS coordinates only";
      }
      return true;
    } catch (e) {
      location.value = "Failed to fetch location";
      coordsText.value = "Error: ${e.toString()}";
      return false;
    }
  }

  Future<void> openCamera() async {
    final captured = await Get.to<File>(() => const FrontCameraCaptureView());
    if (captured != null) selfieImage.value = captured;
  }

  Future<void> confirmCheckIn() async {
    if (selfieImage.value == null) {
      Get.snackbar("Error", "Please take a selfie first",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      // Wait for the GPS fix instead of bouncing the user back to tap
      // again - on a cold start the position simply hasn't landed yet.
      // The address is never a gate: reverse-geocoding needs internet, and
      // raw coordinates are already a complete location.
      if (_currentPosition == null) await _ensureLocation();
      if (_currentPosition == null) {
        Get.snackbar("Error",
            "Could not get your location. Please turn on GPS and try again.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      var request =
          http.MultipartRequest('POST', Uri.parse(apiCheckin));
      request.headers["Authorization"] = "Bearer $token";
      request.fields["location"] =
      _fullAddress.isNotEmpty ? _fullAddress : "${_currentPosition!.latitude},${_currentPosition!.longitude}";
      request.fields["latitude"] = _currentPosition!.latitude.toString();
      request.fields["longitude"] = _currentPosition!.longitude.toString();
      request.fields["dateTime"] = DateTime.now().toIso8601String();
      request.files.add(await http.MultipartFile.fromPath(
        'attendanceImage',
        selfieImage.value!.path,
        contentType: MediaType("image", "jpeg"),
      ));

      final resp = await request.send();
      final res = await http.Response.fromStream(resp);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        Get.showSnackbar(
          const GetSnackBar(
            message: "Checked In Successfully!",
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
          ),
        );
      } else if (res.statusCode == 401) {
        await logout();
      } else {
        selfieImage.value = null;
        try {
          final responseData = jsonDecode(res.body);
          Get.snackbar(
              "Error", responseData['message'] ?? "Check-in failed",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
        } catch (_) {
          Get.snackbar("Error", "Check-in failed",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
        }
      }
    } catch (e) {
      selfieImage.value = null;
      Get.snackbar("Error", "No internet connection. Please try again.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Logout method — data clear karke login par bhejo
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(() => const LoginView());
  }

  void onButtonPressed() {
    if (selfieImage.value != null) {
      confirmCheckIn();
    } else {
      openCamera();
    }
  }
}
