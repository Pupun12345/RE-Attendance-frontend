// lib/screens/supervisor/worker_checkout_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';

class WorkerCheckOutScreen extends StatefulWidget {
  const WorkerCheckOutScreen({Key? key}) : super(key: key);

  @override
  State<WorkerCheckOutScreen> createState() => _WorkerCheckOutScreenState();
}

class _WorkerCheckOutScreenState extends State<WorkerCheckOutScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  String _timeString = "";
  Timer? _timer;
  String _userName = "umesh";
  String _locationText = "Fetching location...";
  File? _lastCapturedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadUserName();
    _determinePositionAndListen();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Start realtime clock (updates every second)
  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? "PM" : "AM";
    setState(() {
      _timeString = "${now.day.toString().padLeft(2, '0')} "
          "${_monthName(now.month)} "
          "${now.year}  "
          "${hour.toString().padLeft(2, '0')}:$minute:$second $ampm";
    });
  }

  String _monthName(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }

  // Load user name from SharedPreferences (expects 'user' JSON or simple 'name' key)
  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        try {
          final Map<String, dynamic> userData = Map<String, dynamic>.from(
              (userString.isNotEmpty && userString.startsWith("{")) ? jsonDecode(userString) : {});
          if (userData.isNotEmpty && userData['name'] != null && userData['name'].toString().trim().isNotEmpty) {
            setState(() => _userName = userData['name'].toString());
            return;
          }
        } catch (_) {
          // ignore and fallback
        }
      }
      final nameKey = prefs.getString('name');
      if (nameKey != null && nameKey.trim().isNotEmpty) {
        setState(() => _userName = nameKey);
      }
    } catch (_) {
      // keep default
    }
  }

  // Get location once and keep it updated (not high-frequency)
  Future<void> _determinePositionAndListen() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationText = "GPS not enabled");
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationText = "Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationText = "Location permission permanently denied");
        return;
      }

      // initial position
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;
      setState(() => _locationText = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}");

      // optional: listen for position changes to update (every few seconds)
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, distanceFilter: 20),
      ).listen((Position position) {
        if (!mounted) return;
        setState(() {
          _locationText = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationText = "Unable to fetch location");
    }
  }

  // Open camera, capture image — you can upload this file afterwards
  Future<void> _openCameraAndCheckOut() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 80);
      if (picked == null) {
        // user cancelled
        return;
      }

      setState(() {
        _lastCapturedImage = File(picked.path);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checked out (image captured)"), backgroundColor: Colors.green),
      );

      // Optionally: navigate back to dashboard
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open camera"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen()),
            );
          },
        ),
        centerTitle: true,
        title: const Text(
          "Punch", // same header as check-in (you asked them consistent)
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time row
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 20, color: Colors.black87),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _timeString,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // User name row
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20, color: Colors.black87),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _userName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // (Optional) last captured image preview
                  if (_lastCapturedImage != null) ...[
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_lastCapturedImage!, height: 220, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 200),
                ],
              ),
            ),

            // Bottom positioned location + button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    alignment: Alignment.centerLeft,
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 20, color: Colors.black87),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _locationText,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8),
                      child: SizedBox(
                        height: 58,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openCameraAndCheckOut,
                          icon: const Icon(Icons.camera_alt, size: 22),
                          label: const Text(
                            "Check Out",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
