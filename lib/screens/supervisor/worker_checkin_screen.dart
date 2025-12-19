// lib/screens/supervisor/worker_checkin_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http_parser/http_parser.dart';
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
  // Constants
  static const String _pendingCheckinQueueKey = 'pending_checkin_queue';
  final Color themeBlue = const Color(0xFF0B3B8C);

  // Connectivity
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Time
  String _timeString = "";
  Timer? _timer;

  // Supervisor Data
  String _supervisorId = "";

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
  String? _pendingName;
  String? _pendingUserId;
  Timer? _pendingTimer;
  int _pendingSecondsLeft = 0;
  bool _pendingEscalated = false;
  int _offlineTryCount = 0;

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadSupervisorId();
    _determinePositionAndListen();
    _listenToNetwork();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _timer?.cancel();
    _pendingTimer?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------------
  // CONNECTIVITY HANDLER
  // ----------------------------------------------------------
  void _listenToNetwork() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    final bool hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection || !mounted) return;

    final uploaded = await _syncPendingAttendance();
    if (uploaded > 0) {
      _showSnack(
        "Network restored. $uploaded pending check-in(s) synced.",
        Colors.green,
      );
    }
  }

  // ----------------------------------------------------------
  // CLOCK
  // ----------------------------------------------------------
  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
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
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }

  // ----------------------------------------------------------
  // LOAD SUPERVISOR ID
  // ----------------------------------------------------------
  Future<void> _loadSupervisorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null && userString.isNotEmpty) {
        try {
          final Map<String, dynamic> userData =
              Map<String, dynamic>.from(jsonDecode(userString));
          if (userData['supervisorId'] != null &&
              userData['supervisorId'].toString().trim().isNotEmpty) {
            setState(() {
              _supervisorId = userData['supervisorId'].toString();
            });
            return;
          }
        } catch (_) {}
      }

      final sup = prefs.getString('supervisorId');
      if (sup != null && sup.trim().isNotEmpty) {
        setState(() {
          _supervisorId = sup;
        });
      }
    } catch (_) {
      // Keep default empty
    }
  }

  // ----------------------------------------------------------
  // LOCATION + ADDRESS
  // ----------------------------------------------------------
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

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (!mounted) return;

      _currentLat = pos.latitude;
      _currentLng = pos.longitude;

      setState(() {
        _locationText =
            "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
      });
      _updateAddress(pos.latitude, pos.longitude);

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 20,
        ),
      ).listen((position) {
        if (!mounted) return;
        _currentLat = position.latitude;
        _currentLng = position.longitude;
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

  // ----------------------------------------------------------
  // CAMERA
  // ----------------------------------------------------------
  Future<void> _openCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 60,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (picked != null) {
        setState(() {
          _lastCapturedImage = File(picked.path);
        });
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack("Failed to open camera", Colors.red);
    }
  }

  // ----------------------------------------------------------
  // HELPERS (TOKEN + SNACKBAR)
  // ----------------------------------------------------------
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }

  // ----------------------------------------------------------
  // IMAGE ENCODING
  // ----------------------------------------------------------
  Future<String> encodeImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Failed to encode image: $e');
    }
  }

  // ----------------------------------------------------------
  // ONLINE CHECK-IN API
  // ----------------------------------------------------------
  Future<void> _sendOnlineCheckin() async {
    final token = await _getToken();
    if (token == null) {
      _showSnack("Not authorized", Colors.redAccent);
      return;
    }
    if (_lastCapturedImage == null) {
      _showSnack("Please capture photo first", Colors.redAccent);
      return;
    }

    try {
      final uri = Uri.parse('$apiBaseUrl/api/v1/attendance/supervisor/checkin');
      var request = http.MultipartRequest('POST', uri);
      print(token);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['workerId'] = widget.workerDbId;
      request.fields['location'] = _addressText;
      request.fields['timeLabel'] = _timeString;
      request.fields['address'] = _addressText;
      if (_currentLat != null) request.fields['lat'] = _currentLat.toString();
      if (_currentLng != null) request.fields['lng'] = _currentLng.toString();
      if (_supervisorId.isNotEmpty) request.fields['supervisorId'] = _supervisorId;

      request.files.add(
        await http.MultipartFile.fromPath(
          'attendanceImage',
          _lastCapturedImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack("Success: ${widget.workerName} Checked In!", Colors.green);
        _clearPending();
        if (mounted) Navigator.pop(context);
      } else {
        Map<String, dynamic>? errorData;
        if (res.body.isNotEmpty) {
          try {
            errorData = jsonDecode(res.body) as Map<String, dynamic>?;
          } catch (_) {}
        }
        _showSnack(
          errorData?['message'] ?? "Server error (${res.statusCode}). Please try again.",
          Colors.orange,
        );
      }
    } catch (e) {
      _showSnack("Network error: $e", Colors.orange);
    }
  }

  // ----------------------------------------------------------
  // LOCAL PENDING QUEUE (CHECK-IN)
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> _loadPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCheckinQueueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePendingQueue(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingCheckinQueueKey, jsonEncode(list));
  }

  Future<void> _addPendingRecordToStorage() async {
    if (_lastCapturedImage == null) return;

    final queue = await _loadPendingQueue();

    final record = <String, dynamic>{
      "type": "CHECK_IN",
      "userId": widget.workerId,
      "userName": widget.workerName,
      "workerDbId": widget.workerDbId,
      "supervisorId": _supervisorId,
      "timeLabel": _timeString,
      "createdAt": DateTime.now().toIso8601String(),
      "address": _addressText,
      "locationLabel": _locationText,
      "lat": _currentLat,
      "lng": _currentLng,
      "imagePath": _lastCapturedImage!.path,
    };

    queue.add(record);
    await _savePendingQueue(queue);
  }

  Future<int> _syncPendingAttendance() async {
    final queue = await _loadPendingQueue();
    if (queue.isEmpty) return 0;

    final token = await _getToken();
    if (token == null) return 0;

    final List<Map<String, dynamic>> remaining = [];
    int uploadedCount = 0;

    for (final item in queue) {
      try {
        final imgPath = item['imagePath'] as String?;
        if (imgPath == null) continue;

        final file = File(imgPath);
        if (!await file.exists()) continue;

        final imgBase64 = await encodeImageToBase64(file);

        final url = Uri.parse('$apiBaseUrl/api/v1/attendance/supervisor/checkin-pending');

        final body = {
          "type": item['type'],
          "userId": item['userId'],
          "userName": item['userName'],
          "workerDbId": item['workerDbId'],
          "supervisorId": item['supervisorId'],
          "timeLabel": item['timeLabel'],
          "createdAt": item['createdAt'],
          "address": item['address'],
          "locationLabel": item['locationLabel'],
          "lat": item['lat'],
          "lng": item['lng'],
          "imageBase64": imgBase64,
        };

        final res = await http.post(
          url,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
          body: jsonEncode(body),
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

    if (uploadedCount > 0 && remaining.isEmpty) {
      _clearPending();
    }

    return uploadedCount;
  }

  // ----------------------------------------------------------
  // PENDING CYCLE (UI STATE)
  // ----------------------------------------------------------
  void _startPendingCycle({required bool allowReset}) {
    _pendingTimer?.cancel();

    setState(() {
      _isPending = true;
      _pendingImage = _lastCapturedImage;
      _pendingTime = _timeString;
      _pendingLocation = _locationText;
      _pendingAddress = _addressText;
      _pendingName = widget.workerName;
      _pendingUserId = widget.workerId;
      _pendingEscalated = false;
      _pendingSecondsLeft = 30;
    });

    _pendingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_pendingSecondsLeft > 0) {
          _pendingSecondsLeft--;
        } else {
          timer.cancel();
          if (allowReset) {
            _isPending = false;
            _pendingSecondsLeft = 0;
            _pendingEscalated = false;
          } else {
            _pendingEscalated = true;
            _pendingSecondsLeft = 0;
          }
        }
      });
    });
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
      _offlineTryCount = 0;
    });
  }

  // ----------------------------------------------------------
  // BUTTON HANDLER
  // ----------------------------------------------------------
  void _confirmCheckIn() async {
    if (_lastCapturedImage == null) {
      _showSnack("Please capture photo first", Colors.redAccent);
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    final bool hasInternet = connectivity.any((r) => r != ConnectivityResult.none);

    if (!hasInternet) {
      _offlineTryCount++;

      if (_offlineTryCount == 1) {
        await _addPendingRecordToStorage();
        _showSnack(
          "No internet. Check-in saved as pending (1st attempt).",
          Colors.orange,
        );
        _startPendingCycle(allowReset: true);
      } else {
        _showSnack(
          "No internet again. Check-in will stay pending until network is back.",
          Colors.deepOrange,
        );
        _startPendingCycle(allowReset: false);
      }
      return;
    }

    _offlineTryCount = 0;
    await _sendOnlineCheckin();
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool hasImage = _lastCapturedImage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SupervisorDashboardScreen(),
            ),
          ),
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
              // Time
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

              // User name + id
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 20, color: Colors.black87),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${widget.workerName} (${widget.workerId})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Photo preview
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

      // FOOTER
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _isPending
                      ? null
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