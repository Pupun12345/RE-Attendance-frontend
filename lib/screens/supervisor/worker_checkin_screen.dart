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
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';

class WorkerCheckInScreen extends StatefulWidget {
  const WorkerCheckInScreen({Key? key}) : super(key: key);

  @override
  State<WorkerCheckInScreen> createState() => _WorkerCheckInScreenState();
}

class _WorkerCheckInScreenState extends State<WorkerCheckInScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  String _timeString = "";
  Timer? _timer; // ✅ Variable declared as _timer

  // User data
  String _userName = "umesh";
  String _userId = "EMP001";

  String _locationText = "Fetching location...";
  String _addressText = "Fetching address...";
  File? _lastCapturedImage;
  final ImagePicker _picker = ImagePicker();

  // Pending state
  bool _isPending = false;
  File? _pendingImage;
  String? _pendingTime;
  String? _pendingLocation;
  String? _pendingAddress;
  String? _pendingName;
  String? _pendingUserId;

  // Pending countdown like Paytm
  Timer? _pendingTimer;
  int _pendingSecondsLeft = 0;
  bool _pendingEscalated = false; // true => send to admin, false => auto-confirm

  // CONNECTIVITY STREAM (connectivity_plus 6.x)
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadUserName();
    _determinePositionAndListen();

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pendingTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  // Start realtime clock (updates every second)
  void _startClock() {
    _updateTime();
    // ✅ FIXED: Used '_timer' and added '(t)' to callback
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());
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
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[m - 1];
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        try {
          final Map<String, dynamic> userData = Map<String, dynamic>.from(
            (userString.isNotEmpty && userString.startsWith("{"))
                ? jsonDecode(userString)
                : {},
          );

          if (userData.isNotEmpty) {
            setState(() {
              if (userData['name'] != null &&
                  userData['name'].toString().trim().isNotEmpty) {
                _userName = userData['name'].toString();
              }
              if (userData['userId'] != null &&
                  userData['userId'].toString().trim().isNotEmpty) {
                _userId = userData['userId'].toString();
              }
            });
            return;
          }
        } catch (_) {}
      }

      final nameKey = prefs.getString('name');
      final idKey = prefs.getString('userId');

      setState(() {
        if (nameKey != null && nameKey.trim().isNotEmpty) {
          _userName = nameKey;
        }
        if (idKey != null && idKey.trim().isNotEmpty) {
          _userId = idKey;
        }
      });
    } catch (_) {
      // ignore and keep defaults
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if ((p.street ?? '').trim().isNotEmpty) p.street,
          if ((p.locality ?? '').trim().isNotEmpty) p.locality,
          if ((p.administrativeArea ?? '').trim().isNotEmpty)
            p.administrativeArea,
          if ((p.country ?? '').trim().isNotEmpty) p.country,
        ];
        setState(() {
          _addressText =
              parts.isNotEmpty ? parts.join(", ") : "Address not available";
        });
      } else {
        setState(() => _addressText = "Address not available");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _addressText = "Unable to fetch address");
    }
  }

  // Get location and listen for updates
  Future<void> _determinePositionAndListen() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationText = "GPS not enabled";
          _addressText = "Location service is off";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationText = "Location permission denied";
            _addressText = "Permission denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = "Location permission permanently denied";
          _addressText = "Enable permission from settings";
        });
        return;
      }

      // initial position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (!mounted) return;

      setState(() {
        _locationText =
            "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
      });
      _updateAddress(pos.latitude, pos.longitude);

      // listen for position changes
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 20,
        ),
      ).listen((Position position) {
        if (!mounted) return;
        setState(() {
          _locationText =
              "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        });
        _updateAddress(position.latitude, position.longitude);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationText = "Unable to fetch location";
        _addressText = "Unable to fetch address";
      });
    }
  }

  Future<void> _openCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      if (picked == null) {
        return; // user cancelled
      }

      setState(() {
        _lastCapturedImage = File(picked.path);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to open camera"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mark attendance as pending (no internet)
  void _markPending() {
    _pendingTimer?.cancel();

    setState(() {
      _isPending = true;
      _pendingImage = _lastCapturedImage;
      _pendingTime = _timeString;
      _pendingLocation = _locationText;
      _pendingAddress = _addressText;
      _pendingName = _userName;
      _pendingUserId = _userId;

      _pendingEscalated = false;
      _pendingSecondsLeft = 30; // countdown like Paytm
    });

    _pendingTimer =
        Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_pendingSecondsLeft > 0) {
          _pendingSecondsLeft--;
        } else {
          // countdown finished -> now it is "stuck" like Paytm payment
          _pendingEscalated = true;
          timer.cancel();
        }
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No internet. Attendance saved as pending."),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _clearPending() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    setState(() {
      _isPending = false;
      _pendingImage = null;
      _pendingTime = null;
      _pendingLocation = null;
      _pendingAddress = null;
      _pendingName = null;
      _pendingUserId = null;
      _pendingSecondsLeft = 0;
      _pendingEscalated = false;
    });
  }

  // Handle connectivity change (LIST VERSION for connectivity_plus 6.x)
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (!_isPending || _pendingImage == null) return;

    final bool hasConnection =
        results.any((r) => r != ConnectivityResult.none);

    if (!hasConnection) return;
    if (!mounted) return;

    // Network aa gaya: Paytm-style settlement
    if (!_pendingEscalated) {
      // within countdown -> treat as success, real-time attendance confirmed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Network restored. Attendance confirmed in system.",
          ),
          backgroundColor: Colors.green,
        ),
      );
      // yahan real API call laga sakte ho for auto-confirm
    } else {
      // countdown ke baad bhi network nahi tha, ab aya -> send to admin
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Network restored late. Attendance sent to admin for approval.",
          ),
          backgroundColor: Colors.deepOrange,
        ),
      );
      // yahan admin ke liye offline record upload ka API laga sakte ho
    }

    _clearPending();
  }

  void _confirmCheckIn() async {
    if (_lastCapturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please capture photo first."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Check network
    final connectivity = await Connectivity().checkConnectivity();
    final bool hasInternet = connectivity != ConnectivityResult.none;

    if (!hasInternet) {
      // No internet -> go to pending mode
      _markPending();
      return;
    }

    // Internet available -> normal real-time attendance (API call yahan)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Checked in successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    // Example: navigate back to dashboard if needed
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen()),
    // );
  }

  // Show Pending Details Card (photo + name + id + time + location)
  void _showPendingDetails() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pending Check-In",
                style: TextStyle(
                  color: themeBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (_pendingImage != null)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: FileImage(_pendingImage!),
                ),
              const SizedBox(height: 16),

              // Name + ID
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.badge_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${_pendingName ?? _userName} (${_pendingUserId ?? _userId})",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pendingTime ?? _timeString,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pendingAddress ?? _addressText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pendingLocation ?? _locationText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(color: themeBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _lastCapturedImage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SupervisorDashboardScreen(),
              ),
            );
          },
        ),
        centerTitle: true,
        title: const Text(
          "Punch",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time row
              Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 20, color: Colors.black87),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _timeString,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // User name + ID row
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 20, color: Colors.black87),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$_userName ($_userId)",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Photo preview in circle
              if (hasImage) ...[
                Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: FileImage(_lastCapturedImage!),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 200),
            ],
          ),
        ),
      ),

      // FOOTER: Address + Lat/Long + Button
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Address + Lat/Long stacked
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Real-time GPS location (human readable)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            size: 20, color: Colors.black87),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _addressText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Lat / Lng
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _locationText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Check In / Confirm Check In / Pending button
              SizedBox(
                height: 58,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPending
                      ? _showPendingDetails
                      : (hasImage ? _confirmCheckIn : _openCamera),
                  icon: Icon(
                    _isPending
                        ? Icons.hourglass_bottom
                        : (hasImage
                            ? Icons.check_circle_outline
                            : Icons.camera_alt),
                    size: 22,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isPending
                        ? (_pendingSecondsLeft > 0
                            ? "Pending (${_pendingSecondsLeft}s)"
                            : "Pending - Waiting for network")
                        : (hasImage ? "Confirm Check In" : "Check In"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isPending ? Colors.orange.shade700 : themeBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}