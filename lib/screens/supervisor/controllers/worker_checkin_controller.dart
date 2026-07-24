// lib/screens/supervisor/controllers/worker_checkin_controller.dart

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

class WorkerCheckInController extends GetxController {
  late String workerName;
  late String workerId;
  late String workerDbId;

  final timeString          = ''.obs;
  final locationText        = 'Fetching location...'.obs;
  final addressText         = 'Fetching address...'.obs;
  final lastCapturedImage   = Rxn<File>();

  final isCheckingIn        = false.obs;
  final checkInSuccess      = false.obs;

  String _supervisorId = '';
  double? _currentLat;
  double? _currentLng;
  bool _offlineAddressWarned = false;

  Timer? _clockTimer;

  final _picker = ImagePicker();

  void init({required String name, required String userId, required String dbId}) {
    workerName = name;
    workerId   = userId;
    workerDbId = dbId;
  }

  @override
  void onInit() {
    super.onInit();
    _startClock();
    _loadSupervisorId();
    _determinePositionAndListen();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }

  // ── Clock ──────────────────────────────────────────────────
  void _startClock() {
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now  = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final min  = now.minute.toString().padLeft(2, '0');
    final sec  = now.second.toString().padLeft(2, '0');
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    timeString.value =
    '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} '
        '${now.year} $hour:$min:$sec $ampm';
  }

  // ── Supervisor ID ──────────────────────────────────────────
  Future<void> _loadSupervisorId() async {
    try {
      final prefs      = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = Map<String, dynamic>.from(jsonDecode(userString));
        if ((userData['supervisorId'] ?? '').toString().trim().isNotEmpty) {
          _supervisorId = userData['supervisorId'].toString();
          return;
        }
      }
      final sup = prefs.getString('supervisorId');
      if (sup != null && sup.trim().isNotEmpty) _supervisorId = sup;
    } catch (_) {}
  }

  // ── Location ───────────────────────────────────────────────
  Future<void> _determinePositionAndListen() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationText.value = 'GPS not enabled';
        addressText.value  = 'Location service is off';
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationText.value = 'Location permission denied';
          addressText.value  = 'Permission denied';
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        locationText.value = 'Location permission permanently denied';
        addressText.value  = 'Enable permission from settings';
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _currentLat        = pos.latitude;
      _currentLng        = pos.longitude;
      locationText.value =
      'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
      _updateAddress(pos.latitude, pos.longitude);

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low, distanceFilter: 20),
      ).listen((position) {
        _currentLat        = position.latitude;
        _currentLng        = position.longitude;
        locationText.value =
        'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        _updateAddress(position.latitude, position.longitude);
      });
    } catch (_) {
      locationText.value = 'Unable to fetch location';
      addressText.value  = 'Unable to fetch address';
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p     = placemarks.first;
        final parts = [
          if ((p.street             ?? '').trim().isNotEmpty) p.street,
          if ((p.locality           ?? '').trim().isNotEmpty) p.locality,
          if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea,
          if ((p.country            ?? '').trim().isNotEmpty) p.country,
        ];
        addressText.value =
        parts.isNotEmpty ? parts.join(', ') : 'Address not available';
        _offlineAddressWarned = false;
      }
    } catch (_) {
      // placemarkFromCoordinates needs internet even though GPS itself
      // doesn't - a failure here almost always means no network. Fall back
      // to the raw coordinates (still accurate) instead of blocking, and
      // let the caller know why the address text looks different. The
      // position stream can retry this often, so only warn once.
      addressText.value = '$lat, $lng';
      if (!_offlineAddressWarned) {
        _offlineAddressWarned = true;
        _showSnack('No internet - address lookup skipped, using GPS coordinates',
            Colors.orange);
      }
    }
  }

  // ── Camera ─────────────────────────────────────────────────
  Future<void> openCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 60,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) lastCapturedImage.value = File(picked.path);
    } catch (_) {
      _showSnack('Failed to open camera', Colors.red);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _showSnack(String msg, Color color) {
    Get.snackbar('', msg,
        backgroundColor: color,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12));
  }

  // ── Check-In ───────────────────────────────────────────────
  Future<void> confirmCheckIn() async {
    if (lastCapturedImage.value == null) {
      _showSnack('Please capture photo first', Colors.redAccent);
      return;
    }

    final token = await _getToken();
    if (token == null) { _showSnack('Not authorized', Colors.redAccent); return; }

    isCheckingIn.value   = true;
    checkInSuccess.value = false;

    try {
      final uri     = Uri.parse(apiSupervisorCheckin);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['workerId']    = workerDbId;
      request.fields['location']    = addressText.value;
      request.fields['timeLabel']   = timeString.value;
      request.fields['address']     = addressText.value;
      if (_currentLat != null) request.fields['lat'] = _currentLat.toString();
      if (_currentLng != null) request.fields['lng'] = _currentLng.toString();
      if (_supervisorId.isNotEmpty) request.fields['supervisorId'] = _supervisorId;

      request.files.add(await http.MultipartFile.fromPath(
        'attendanceImage',
        lastCapturedImage.value!.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final res = await http.Response.fromStream(await request.send());

      if (res.statusCode == 200 || res.statusCode == 201) {
        checkInSuccess.value = true;
        _showSnack('✅ $workerName Checked In Successfully!', Colors.green);
        await Future.delayed(const Duration(milliseconds: 1200));
        Get.back();
      } else {
        Map<String, dynamic>? errorData;
        try { errorData = jsonDecode(res.body); } catch (_) {}
        _showSnack(
            errorData?['message'] ?? 'Server error (${res.statusCode}).',
            Colors.orange);
      }
    } catch (e) {
      _showSnack('No internet connection. Please try again.', Colors.orange);
    } finally {
      isCheckingIn.value = false;
    }
  }
}
