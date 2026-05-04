import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

import '../login/login_view.dart'; // 👈 apna login view import karo

class SelfieCheckInController extends GetxController {
  final Color themeBlue = const Color(0xFF0B3B8C);

  final dateTime = ''.obs;
  final location = 'Fetching location...'.obs;
  final coordsText = 'Fetching coordinates...'.obs;
  final selfieImage = Rxn<File>();
  final isLoading = false.obs;
  final isPendingMode = false.obs;
  final isRetrying = false.obs;
  final retrySeconds = 0.obs;

  String _fullAddress = '';
  Position? _currentPosition;
  String _userName = 'Unknown';

  Timer? _retryTimer;
  Timer? _dateTimer;
  StreamSubscription? _connectivitySub;

  @override
  void onInit() {
    super.onInit();
    _startDateTimer();
    _fetchLocation();
    _loadUserData();
    _checkPendingData();
    _checkConnectivityAndSync();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _attemptSync();
      }
    });
  }

  @override
  void onClose() {
    _retryTimer?.cancel();
    _dateTimer?.cancel();
    _connectivitySub?.cancel();
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

  Future<void> _checkPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString("pending_checkin");
    if (pending != null) {
      final jsonData = jsonDecode(pending);
      bool needsAdmin = jsonData['needsAdminApproval'] ?? false;
      isPendingMode.value = true;
      selfieImage.value = File(jsonData['imagePath']);
      coordsText.value =
      "Lat: ${jsonData['lat']}, Lng: ${jsonData['lng']}";
      location.value = jsonData['location'];
      _fullAddress = jsonData['fullAddress'] ?? '';
      dateTime.value = jsonData['displayTime'] ?? 'Pending Time';
      if (needsAdmin) retrySeconds.value = 60;
    }
  }

  Future<void> _checkConnectivityAndSync() async {
    final results = await Connectivity().checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      _attemptSync();
    }
  }

  Future<void> _attemptSync() async {
    if (!isPendingMode.value) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString("pending_checkin");
    if (pending == null) return;
    final pendingData = jsonDecode(pending);
    await _uploadData(
      img: File(pendingData['imagePath']),
      lat: pendingData['lat'],
      lng: pendingData['lng'],
      address: pendingData['fullAddress'] ?? '',
      dt: pendingData['dateTime'],
      isRetry: true,
      sendToAdminQueue: pendingData['needsAdminApproval'] ?? false,
    );
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      location.value = "Location services disabled";
      coordsText.value = "Enable GPS";
      return;
    }

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      location.value = "Location permission denied";
      coordsText.value = "Allow location access";
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPosition = pos;
      coordsText.value =
      "Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}";

      List<Placemark> places =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (places.isNotEmpty) {
        Placemark place = places.first;
        List<String> parts = [];
        if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (place.subAdministrativeArea?.isNotEmpty == true)
          parts.add(place.subAdministrativeArea!);
        if (place.administrativeArea?.isNotEmpty == true)
          parts.add(place.administrativeArea!);
        if (place.postalCode?.isNotEmpty == true) parts.add(place.postalCode!);
        if (place.country?.isNotEmpty == true) parts.add(place.country!);

        _fullAddress = parts.join(", ");
        location.value =
        "${place.locality ?? "Unknown"}, ${place.subLocality ?? ""}";
      }
    } catch (e) {
      location.value = "Failed to fetch location";
      coordsText.value = "Error: ${e.toString()}";
    }
  }

  Future<void> openCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (picked != null) selfieImage.value = File(picked.path);
  }

  Future<void> confirmCheckIn() async {
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

    await _uploadData(
      img: selfieImage.value!,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      address: _fullAddress,
      dt: '',
      isRetry: false,
      sendToAdminQueue: false,
    );
  }

  // ✅ Logout method — data clear karke login par bhejo
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(() => const LoginView());
  }

  Future<void> _uploadData({
    required File img,
    required double lat,
    required double lng,
    required String address,
    required String dt,
    required bool isRetry,
    required bool sendToAdminQueue,
  }) async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final endpoint = sendToAdminQueue
          ? "$apiBaseUrl/api/v1/attendance/checkin-pending"
          : "$apiBaseUrl/api/v1/attendance/checkin";

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers["Authorization"] = "Bearer $token";
      request.fields["location"] =
      address.isNotEmpty ? address : "$lat,$lng";
      request.fields["latitude"] = lat.toString();
      request.fields["longitude"] = lng.toString();
      request.fields["dateTime"] =
      isRetry ? dt : DateTime.now().toIso8601String();
      request.files.add(await http.MultipartFile.fromPath(
        'attendanceImage',
        img.path,
        contentType: MediaType("image", "jpeg"),
      ));

      final resp = await request.send();
      final res = await http.Response.fromStream(resp);

      // ✅ Success response from backend (any 2xx code)
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // _retryTimer?.cancel();
        // await prefs.remove("pending_checkin");
        // isPendingMode.value = false;
        // isRetrying.value = false;

        Get.showSnackbar(
          const GetSnackBar(
            message: "Checked In Successfully!",
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
          ),
        );


        // ✅ 401 — Unauthorized, logout karke login par bhejo
      } else if (res.statusCode == 401) {
        await logout();

        // ✅ Other errors
      } else {
        _retryTimer?.cancel();
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
      if (!isRetry) _startOneMinuteTimer();
    } finally {
      isLoading.value = false;
    }
  }

  void _startOneMinuteTimer() {
    _savePending(needsAdminApproval: false);
    isRetrying.value = true;
    retrySeconds.value = 0;

    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      retrySeconds.value++;
      if (retrySeconds.value % 5 == 0) _checkConnectivityAndSync();
      if (retrySeconds.value >= 60) {
        timer.cancel();
        isRetrying.value = false;
        _savePending(needsAdminApproval: true);
        Get.snackbar(
            "Timeout",
            "Network timeout. Request saved for Admin Approval.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4));
      }
    });
  }

  Future<void> _savePending({required bool needsAdminApproval}) async {
    if (selfieImage.value == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final String fileName =
        'checkin_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = path.join(directory.path, fileName);
    final File newImage = await selfieImage.value!.copy(newPath);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        "pending_checkin",
        jsonEncode({
          "imagePath": newImage.path,
          "lat": _currentPosition!.latitude,
          "lng": _currentPosition!.longitude,
          "fullAddress": _fullAddress,
          "dateTime": DateTime.now().toIso8601String(),
          "displayTime": dateTime.value,
          "location": location.value,
          "needsAdminApproval": needsAdminApproval,
        }));
    isPendingMode.value = true;
    selfieImage.value = newImage;
    if (!needsAdminApproval && retrySeconds.value == 0) {
      Get.snackbar("No Internet", "Retrying for 1 minute...",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void onButtonPressed() {
    if (isPendingMode.value) {
      _attemptSync();
    } else if (selfieImage.value != null) {
      confirmCheckIn();
    } else {
      openCamera();
    }
  }
}