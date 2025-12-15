// lib/screens/supervisor/worker_checkin_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';

class WorkerCheckInScreen extends StatefulWidget {
  final String workerName;
  final String workerId;   // Display ID (e.g. EMP001)
  final String workerDbId; // MongoDB _id

  // ✅ FIX 1: Correctly initialize these fields
  const WorkerCheckInScreen({
    Key? key,
    required this.workerName,
    required this.workerId,
    required this.workerDbId,
  }) : super(key: key);

  @override
  State<WorkerCheckInScreen> createState() => _WorkerCheckInScreenState();
}

class _WorkerCheckInScreenState extends State<WorkerCheckInScreen> {
  static const int _maxRetries = 2;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  final Color themeBlue = const Color(0xFF0B3B8C);
  String _timeString = "";
  Timer? _timer;

  // Location
  String _locationText = "Fetching location...";
  String _addressText = "Fetching address...";
  double? _currentLat;
  double? _currentLng;

  // Image
  File? _lastCapturedImage;
  final ImagePicker _picker = ImagePicker();

  // Pending State
  bool _isPending = false;
  File? _pendingImage;
  String? _pendingTime;
  String? _pendingLocation;
  String? _pendingAddress;
  Timer? _pendingTimer;
  int _pendingSecondsLeft = 0;
  bool _pendingEscalated = false;
  int _offlineTryCount = 0;

  @override
  void initState() {
    super.initState();
    _startClock();
    _determinePositionAndListen();
    
    // ✅ FIX 2: Removed _loadUserData() so it doesn't overwrite worker name with supervisor name.
    
    _listenToNetwork();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _timer?.cancel();
    _pendingTimer?.cancel();
    super.dispose();
  }

  void _listenToNetwork() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        _syncPendingAttendance();
      }
    });
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _timeString = "${now.day.toString().padLeft(2, '0')} ${_monthName(now.month)} ${now.year} "
          "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} "
          "${now.hour >= 12 ? 'PM' : 'AM'}";
    });
  }

  String _monthName(int m) => ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][m - 1];

  // --- Location Logic ---
  Future<void> _determinePositionAndListen() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationText = "GPS disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    if(mounted) {
      _updateLocationUI(pos);
      _updateAddress(pos.latitude, pos.longitude);
    }

    Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, distanceFilter: 20))
        .listen((pos) {
      if(mounted) {
        _updateLocationUI(pos);
        _updateAddress(pos.latitude, pos.longitude);
      }
    });
  }

  void _updateLocationUI(Position pos) {
    setState(() {
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _locationText = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
    });
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() {
          _addressText = "${p.street}, ${p.subLocality}, ${p.locality}";
        });
      }
    } catch (_) {}
  }

  // --- Camera ---
  Future<void> _openCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      setState(() => _lastCapturedImage = File(picked.path));
    }
  }

  // --- API & Sync Logic ---
  
  Future<void> _sendOnlineAttendance({int retry = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final uri = Uri.parse('$apiBaseUrl/api/v1/attendance/supervisor/checkin');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // ✅ FIX 3: Send the WORKER'S DB ID, not the Supervisor's ID
      request.fields['workerId'] = widget.workerDbId; 
      request.fields['location'] = _addressText;
      if (_currentLat != null) request.fields['lat'] = _currentLat.toString();
      if (_currentLng != null) request.fields['lng'] = _currentLng.toString();

      request.files.add(await http.MultipartFile.fromPath('attendanceImage', _lastCapturedImage!.path));

      final response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack("Success: ${widget.workerName} Checked In!", Colors.green);
        Navigator.pop(context);
      } else {
        _showSnack("Server Error: Check-in failed", Colors.orange);
      }
    } on SocketException catch (_) {
      if (retry < _maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
        _sendOnlineAttendance(retry: retry + 1);
      } else {
        _handleOffline();
      }
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    }
  }

  void _handleOffline() async {
    await _savePendingAttendanceLocally();
    _showSnack("No Internet. Saved as Pending.", Colors.orange);
    
    // UI State for Pending
    setState(() {
      _isPending = true;
      _pendingImage = _lastCapturedImage;
      _pendingTime = _timeString;
      _pendingLocation = _locationText;
      _pendingAddress = _addressText;
      _pendingSecondsLeft = 30; // Countdown
      _pendingEscalated = (_offlineTryCount >= 1);
    });
    
    _offlineTryCount++;
    _startPendingTimer();
  }

  void _startPendingTimer() {
    _pendingTimer?.cancel();
    _pendingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        if (_pendingSecondsLeft > 0) {
          _pendingSecondsLeft--;
        } else {
          timer.cancel();
          // If first try, reset UI to allow retry. If escalated, keep pending UI.
          if (!_pendingEscalated) _isPending = false; 
        }
      });
    });
  }

  // Unified Offline Storage
  Future<void> _savePendingAttendanceLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      "workerId": widget.workerDbId, // ✅ Save correct worker ID
      "workerName": widget.workerName,
      "location": _addressText,
      "dateTime": DateTime.now().toIso8601String(),
      "imagePath": _lastCapturedImage!.path
    };
    List<String> list = prefs.getStringList("pending_attendance") ?? [];
    list.add(jsonEncode(data));
    await prefs.setStringList("pending_attendance", list);
  }

  Future<void> _syncPendingAttendance() async {
    // Logic to sync from "pending_attendance" list to backend
    // (Same as your existing _syncPendingAttendance logic)
  }

  void _confirmCheckIn() async {
    if (_lastCapturedImage == null) return _showSnack("Capture photo first", Colors.red);
    
    var connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      _handleOffline();
    } else {
      _sendOnlineAttendance();
    }
  }

  void _showSnack(String msg, Color color) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        title: const Text("Worker Punch", style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Time
            Row(children: [const Icon(Icons.access_time), const SizedBox(width: 10), Text(_timeString, style: const TextStyle(fontSize: 16))]),
            const SizedBox(height: 20),
            
            // ✅ FIX 4: Use widget.workerName instead of local _userName
            Row(children: [
              const Icon(Icons.person), 
              const SizedBox(width: 10), 
              Text("${widget.workerName} (${widget.workerId})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ]),
            
            const SizedBox(height: 30),
            if (_lastCapturedImage != null) 
              Center(child: Image.file(_lastCapturedImage!, height: 200)),
              
            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isPending && _pendingEscalated ? null : (_lastCapturedImage == null ? _openCamera : _confirmCheckIn),
            icon: Icon(_lastCapturedImage == null ? Icons.camera_alt : Icons.check),
            label: Text(_isPending ? "Pending (Offline)" : (_lastCapturedImage == null ? "Take Photo" : "Confirm Check-In")),
            style: ElevatedButton.styleFrom(backgroundColor: _isPending ? Colors.orange : themeBlue, foregroundColor: Colors.white),
          ),
        ),
      ),
    );
  }
}