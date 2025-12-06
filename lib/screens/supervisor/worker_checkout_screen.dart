// lib/screens/supervisor/worker_checkout_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  String _addressText = "Fetching address...";
  File? _lastCapturedImage;
  final ImagePicker _picker = ImagePicker();

  // 🔹 Pending state (offline mode)
  bool _isPending = false;
  File? _pendingImage;
  String? _pendingTime;
  String? _pendingLocation;
  String? _pendingAddress;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadUserName();
    _determinePositionAndListen();

    // 🔹 Listen network for pending sync
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? "PM" : "AM";
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    setState(() {
      _timeString = "${now.day.toString().padLeft(2, '0')} "
          "${_monthName(now.month)} ${now.year} "
          "$hour:$minute:$second $ampm";
    });
  }

  String _monthName(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    if (name != null && name.trim().isNotEmpty) {
      setState(() => _userName = name);
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _addressText =
          "${p.street ?? ""}, ${p.locality ?? ""}, ${p.administrativeArea ?? ""}";
        });
      }
    } catch (_) {}
  }

  Future<void> _determinePositionAndListen() async {
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _locationText =
      "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
    });
    _updateAddress(pos.latitude, pos.longitude);

    Geolocator.getPositionStream().listen((position) {
      if (!mounted) return;
      setState(() {
        _locationText =
        "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
      });
      _updateAddress(position.latitude, position.longitude);
    });
  }

  Future<void> _openCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _lastCapturedImage = File(picked.path);
      });
    }
  }

  // 🔹 Mark pending on no network
  void _markPendingCheckout() {
    setState(() {
      _isPending = true;
      _pendingImage = _lastCapturedImage;
      _pendingTime = _timeString;
      _pendingLocation = _locationText;
      _pendingAddress = _addressText;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No internet. Checkout saved as pending."),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 🔹 Auto send when internet back
  void _handleConnectivityChange(List<ConnectivityResult> result) {
    if (!_isPending) return;
    bool hasNetwork = result.any((r) => r != ConnectivityResult.none);
    if (!hasNetwork) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            "Network restored. Pending checkout sent to admin for approval."),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _isPending = false;
      _pendingImage = null;
      _pendingTime = null;
      _pendingLocation = null;
      _pendingAddress = null;
    });
  }

  // 🔹 Confirm Checkout
  void _confirmCheckOut() async {
    if (_lastCapturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please capture photo first"),
            backgroundColor: Colors.red),
      );
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    bool hasInternet = connectivity != ConnectivityResult.none;

    if (!hasInternet) {
      _markPendingCheckout();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Checked Out Successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 🔹 Show pending details card
  void _showPendingDetails() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Pending Check-Out",
                  style: TextStyle(
                      color: themeBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),
              CircleAvatar(
                  radius: 60, backgroundImage: FileImage(_pendingImage!)),
              const SizedBox(height: 12),
              Text(_pendingTime ?? "", style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(_pendingAddress ?? "",
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(_pendingLocation ?? "",
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close", style: TextStyle(color: themeBlue)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = _lastCapturedImage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SupervisorDashboardScreen())),
        ),
        centerTitle: true,
        title: const Text("Punch",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),

      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.access_time_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_timeString)),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_userName)),
                ]),
                const SizedBox(height: 30),
                if (hasImage)
                  Center(
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: FileImage(_lastCapturedImage!),
                    ),
                  ),
                const SizedBox(height: 200),
              ],
            ),
          )),

      // 🔹 Footer
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 8),
              Expanded(child: Text(_addressText)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.gps_fixed),
              const SizedBox(width: 6),
              Expanded(child: Text(_locationText)),
            ]),
            const SizedBox(height: 8),

            // 🔹 Button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed:
                _isPending ? _showPendingDetails
                    : (hasImage ? _confirmCheckOut : _openCamera),
                icon: Icon(
                  _isPending ? Icons.hourglass_bottom : Icons.camera_alt,
                  color: Colors.white,
                ),
                label: Text(
                  _isPending
                      ? "Pending"
                      : (hasImage ? "Confirm Check Out" : "Check Out"),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _isPending ? Colors.orange.shade700 : themeBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
