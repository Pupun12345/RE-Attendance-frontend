import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/utils/constants.dart';

import '../login/login_view.dart'; // 👈 apna sahi path use karo

class SelfieCheckOutController extends GetxController {
  final Color themeBlue = const Color(0xFF0B3B8C);

  final dateTime = ''.obs;
  final location = 'Fetching location...'.obs;
  final coordsText = 'Fetching coordinates...'.obs;
  final selfieImage = Rxn<File>();
  final isLoading = false.obs;

  String _fullAddress = '';
  Position? _currentPosition;
  String _userName = 'Unknown';

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
    _userName = prefs.getString('userName') ?? 'Unknown';
  }

  String get userName => _userName;

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      location.value = "Location services disabled";
      coordsText.value = "Enable GPS";
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        location.value = "Location permission denied";
        coordsText.value = "Allow location access";
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      location.value = "Permission permanently denied";
      coordsText.value = "Check app settings";
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      _currentPosition = pos;
      coordsText.value =
      "Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}";

      try {
        List<Placemark> placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          List<String> parts = [];
          if (place.subLocality?.isNotEmpty == true) {
            parts.add(place.subLocality!);
          }
          if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
          if (place.subAdministrativeArea?.isNotEmpty == true) {
            parts.add(place.subAdministrativeArea!);
          }
          if (place.administrativeArea?.isNotEmpty == true) {
            parts.add(place.administrativeArea!);
          }
          if (place.postalCode?.isNotEmpty == true) {
            parts.add(place.postalCode!);
          }
          if (place.country?.isNotEmpty == true) parts.add(place.country!);
          _fullAddress = parts.join(", ");
          location.value =
          "${place.locality ?? "Unknown"}, ${place.subLocality ?? ""}";
        }
      } catch (_) {
        location.value =
        "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        _fullAddress = "${pos.latitude},${pos.longitude}";
      }
    } catch (e) {
      location.value = "Failed to fetch location";
      coordsText.value = "Error: ${e.toString()}";
    }
  }

  Future<void> openCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 85);
      if (pickedFile != null) selfieImage.value = File(pickedFile.path);
    } catch (e) {
      Get.snackbar("Error", "Camera not available on this device.",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> confirmCheckout() async {
    if (selfieImage.value == null) {
      Get.snackbar("Error", "Please take a selfie first",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (_currentPosition == null) {
      Get.snackbar("Error", "Location not available. Please wait...",
          backgroundColor: Colors.red, colorText: Colors.white);
      _fetchLocation();
      return;
    }
    if (_fullAddress.isEmpty) {
      Get.snackbar("Error", "Address not available. Please wait...",
          backgroundColor: Colors.red, colorText: Colors.white);
      _fetchLocation();
      return;
    }

    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request =
          http.MultipartRequest('POST', Uri.parse(apiCheckout));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['location'] =
          _fullAddress.isNotEmpty ? _fullAddress : "${_currentPosition!.latitude},${_currentPosition!.longitude}";
      request.fields['latitude'] = _currentPosition!.latitude.toString();
      request.fields['longitude'] = _currentPosition!.longitude.toString();
      request.fields['dateTime'] = DateTime.now().toIso8601String();
      request.files.add(await http.MultipartFile.fromPath(
          'attendanceImage', selfieImage.value!.path,
          contentType: MediaType('image', 'jpeg')));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Get.showSnackbar(
          const GetSnackBar(
            message: "Checked Out Successfully!",
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
          ),
        );
      } else if (response.statusCode == 401) {
        await logout();
      } else {
        try {
          final responseData = jsonDecode(response.body);
          Get.snackbar(
              "Error", responseData['message'] ?? "Check-out failed",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
        } catch (_) {
          Get.snackbar("Error", "Check-out failed",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
        }
      }
    } catch (e) {
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
      confirmCheckout();
    } else {
      openCamera();
    }
  }
}
