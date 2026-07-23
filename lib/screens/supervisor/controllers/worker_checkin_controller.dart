// lib/screens/supervisor/controllers/worker_checkin_controller.dart

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
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/utils/constants.dart';

class WorkerCheckInController extends GetxController {
  static const String _pendingCheckinQueueKey = 'pending_checkin_queue';

  late String workerName;
  late String workerId;
  late String workerDbId;

  final timeString          = ''.obs;
  final locationText        = 'Fetching location...'.obs;
  final addressText         = 'Fetching address...'.obs;
  final lastCapturedImage   = Rxn<File>();
  final isPending           = false.obs;
  final pendingSecondsLeft  = 0.obs;
  final pendingEscalated    = false.obs;

  final isCheckingIn        = false.obs;
  final checkInSuccess      = false.obs;

  String _supervisorId = '';
  double? _currentLat;
  double? _currentLng;
  int _offlineTryCount = 0;

  Timer? _clockTimer;
  Timer? _pendingTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

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
    _listenToNetwork();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _pendingTimer?.cancel();
    _connectivitySub?.cancel();
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
      }
    } catch (_) {
      addressText.value = 'Unable to fetch address';
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

  // ── Online Check-In ────────────────────────────────────────
  Future<void> _sendOnlineCheckin() async {
    final token = await _getToken();
    if (token == null) { _showSnack('Not authorized', Colors.redAccent); return; }
    if (lastCapturedImage.value == null) {
      _showSnack('Please capture photo first', Colors.redAccent);
      return;
    }

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
        _clearPending();
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
      _showSnack('Network error: $e', Colors.orange);
    } finally {
      // ── FIX: hamesha loader band karo — success state alag track hoti hai
      isCheckingIn.value = false;
    }
  }

  // ── Offline Queue ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _loadPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_pendingCheckinQueueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (_) { return []; }
  }

  Future<void> _savePendingQueue(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingCheckinQueueKey, jsonEncode(list));
  }

  Future<void> _addPendingRecordToStorage() async {
    if (lastCapturedImage.value == null) return;
    final queue = await _loadPendingQueue();
    queue.add({
      'type'         : 'CHECK_IN',
      'userId'       : workerId,
      'userName'     : workerName,
      'workerDbId'   : workerDbId,
      'supervisorId' : _supervisorId,
      'timeLabel'    : timeString.value,
      'createdAt'    : DateTime.now().toIso8601String(),
      'address'      : addressText.value,
      'locationLabel': locationText.value,
      'lat'          : _currentLat,
      'lng'          : _currentLng,
      'imagePath'    : lastCapturedImage.value!.path,
    });
    await _savePendingQueue(queue);
  }

  Future<int> _syncPendingAttendance() async {
    final queue = await _loadPendingQueue();
    if (queue.isEmpty) return 0;
    final token = await _getToken();
    if (token == null) return 0;

    final remaining     = <Map<String, dynamic>>[];
    int uploadedCount   = 0;

    for (final item in queue) {
      try {
        final imgPath = item['imagePath'] as String?;
        if (imgPath == null) continue;
        final file = File(imgPath);
        if (!await file.exists()) continue;

        final imgBase64 = base64Encode(await file.readAsBytes());
        final res = await http.post(
          Uri.parse(apiSupervisorCheckinPending),
          headers: {
            HttpHeaders.contentTypeHeader  : 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
          body: jsonEncode({...item, 'imageBase64': imgBase64}),
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          uploadedCount++;
        } else {
          remaining.add(item);
        }
      } catch (e) {
        debugPrint('Error syncing item: $e');
        remaining.add(item);
      }
    }

    await _savePendingQueue(remaining);
    if (uploadedCount > 0 && remaining.isEmpty) _clearPending();
    return uploadedCount;
  }

  // ── Pending UI Cycle ───────────────────────────────────────
  void _startPendingCycle({required bool allowReset}) {
    _pendingTimer?.cancel();
    isPending.value           = true;
    pendingEscalated.value    = false;
    pendingSecondsLeft.value  = 30;

    _pendingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (pendingSecondsLeft.value > 0) {
        pendingSecondsLeft.value--;
      } else {
        timer.cancel();
        if (allowReset) {
          isPending.value           = false;
          pendingSecondsLeft.value  = 0;
          pendingEscalated.value    = false;
        } else {
          pendingEscalated.value   = true;
          pendingSecondsLeft.value = 0;
        }
      }
    });
  }

  void _clearPending() {
    _pendingTimer?.cancel();
    isPending.value           = false;
    pendingSecondsLeft.value  = 0;
    pendingEscalated.value    = false;
    _offlineTryCount          = 0;
  }

  // ── Network Listener ───────────────────────────────────────
  void _listenToNetwork() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
          final hasConnection =
          results.any((r) => r != ConnectivityResult.none);
          if (!hasConnection) return;
          final uploaded = await _syncPendingAttendance();
          if (uploaded > 0) {
            _showSnack(
                'Network restored. $uploaded pending check-in(s) synced.',
                Colors.green);
          }
        });
  }

  // ── Main Button Handler ────────────────────────────────────
  Future<void> confirmCheckIn() async {
    if (lastCapturedImage.value == null) {
      _showSnack('Please capture photo first', Colors.redAccent);
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet  =
    connectivity.any((r) => r != ConnectivityResult.none);

    if (!hasInternet) {
      _offlineTryCount++;
      if (_offlineTryCount == 1) {
        await _addPendingRecordToStorage();
        _showSnack(
            'No internet. Check-in saved as pending (1st attempt).',
            Colors.orange);
        _startPendingCycle(allowReset: true);
      } else {
        _showSnack(
            'No internet again. Check-in will stay pending until network is back.',
            Colors.deepOrange);
        _startPendingCycle(allowReset: false);
      }
      return;
    }

    _offlineTryCount = 0;
    await _sendOnlineCheckin();
  }
}