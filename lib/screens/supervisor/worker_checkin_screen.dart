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
  const WorkerCheckInScreen({Key? key}) : super(key: key);

  @override
  State<WorkerCheckInScreen> createState() => _WorkerCheckInScreenState();
}

class _WorkerCheckInScreenState extends State<WorkerCheckInScreen> {

    static const int _maxRetries = 2;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  

  final Color themeBlue = const Color(0xFF0B3B8C);
  String _timeString = "";
  Timer? _timer;

  // ---------------- USER DATA ----------------
  String _userName = "umesh";
  String _userId = "EMP001";
  String _supervisorId = "SUP001";

  // ---------------- LOCATION DATA ----------------
  String _locationText = "Fetching location...";
  String _addressText = "Fetching address...";
  double? _currentLat;
  double? _currentLng;

  // ---------------- IMAGE ----------------
  File? _lastCapturedImage;
  final ImagePicker _picker = ImagePicker();

  // ---------------- PENDING STATE (UI ONLY) ----------------
  bool _isPending = false;
  File? _pendingImage;
  String? _pendingTime;
  String? _pendingLocation;
  String? _pendingAddress;
  String? _pendingName;
  String? _pendingUserId;

  Timer? _pendingTimer;
  int _pendingSecondsLeft = 0;
  bool _pendingEscalated = false; // final stuck state after 2nd attempt
  int _offlineTryCount = 0;       // 0 = none, 1 = first try done, >=2 = second/final

 
  // SharedPrefs key for JSON queue
  static const String _pendingQueueKey = 'pending_attendance_queue';

  @override
  void initState() {
    super.initState();
    _listenToNetwork();  
    _startClock();
    _loadUserData();
    _determinePositionAndListen();

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

 @override
void dispose() {
  _connectivitySub?.cancel();
  super.dispose();
}



 

void _listenToNetwork() {
  _connectivitySub = Connectivity()
      .onConnectivityChanged
      .listen((List<ConnectivityResult> results) {
    print("📡 Connectivity changed: $results");

    final hasConnection = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi);

    if (hasConnection) {
      print("✅ Online again, syncing pending attendance...");
      _syncPendingAttendance();
    }
  });
}





  // ----------------------------------------------------------
  // REAL TIME CLOCK
  // ----------------------------------------------------------
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

  // ----------------------------------------------------------
  // LOAD USER + SUPERVISOR DATA FROM STORAGE
  // ----------------------------------------------------------
  Future<void> _loadUserData() async {
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
              if (userData['supervisorId'] != null &&
                  userData['supervisorId'].toString().trim().isNotEmpty) {
                _supervisorId = userData['supervisorId'].toString();
              }
            });
            return;
          }
        } catch (_) {}
      }

      final nameKey = prefs.getString('name');
      final idKey = prefs.getString('userId');
      final supKey = prefs.getString('supervisorId');

      setState(() {
        if (nameKey != null && nameKey.trim().isNotEmpty) {
          _userName = nameKey;
        }
        if (idKey != null && idKey.trim().isNotEmpty) {
          _userId = idKey;
        }
        if (supKey != null && supKey.trim().isNotEmpty) {
          _supervisorId = supKey;
        }
      });
    } catch (_) {
      // keep defaults
    }
  }

  // ----------------------------------------------------------
  // ADDRESS / LOCATION
  // ----------------------------------------------------------
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
      ).listen((Position position) {
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

  // ----------------------------------------------------------
  // CAMERA
  // ----------------------------------------------------------
  Future<void> _openCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      if (picked == null) {
        return;
      }

      setState(() {
        _lastCapturedImage = File(picked.path);
      });
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
  // OFFLINE QUEUE (PHONE STORAGE JSON)
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> _loadPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingQueueKey);
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
    await prefs.setString(_pendingQueueKey, jsonEncode(list));
  }

  /// Save record in local queue (worker id, supervisor, time, location, image path)
  Future<void> _addPendingRecordToStorage() async {
    if (_lastCapturedImage == null) return;

    final queue = await _loadPendingQueue();

    final record = <String, dynamic>{
      "userId": _userId,
      "userName": _userName,
      "supervisorId": _supervisorId,
      "timeLabel": _timeString,
      "createdAt": DateTime.now().toIso8601String(),
      "address": _addressText,
      "locationLabel": _locationText,
      "lat": _currentLat,
      "lng": _currentLng,
      "imagePath": _lastCapturedImage!.path,
    };

    queue.add(record); // FIFO
    await _savePendingQueue(queue);
  }

  /// When network comes back, push all pending JSON to backend FIFO
  Future<int> _syncPendingQueueToBackend() async {
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

        final imgBytes = await file.readAsBytes();
        final imgBase64 = base64Encode(imgBytes);

        // DUMMY Pending Attendance API
        //final url = Uri.parse('$apiBaseUrl/api/v1/attendance/pending');
        final url = Uri.parse('$apiBaseUrl/api/v1/attendance/supervisor/checkin-pending');

        final body = {
          "userId": item['userId'],
          "userName": item['userName'],
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
      } catch (_) {
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
  // PENDING MODE (1st + 2nd ATTEMPT)
  // ----------------------------------------------------------

  /// Common pending cycle. allowReset = true for 1st time, false for 2nd time.
  void _startPendingCycle({required bool allowReset}) {
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
            // 1st try over -> back to normal "Confirm Check In"
            _isPending = false;
            _pendingSecondsLeft = 0;
            _pendingEscalated = false;
          } else {
            // 2nd try over -> stuck pending until network comes (Paytm style)
            _pendingEscalated = true;
            _pendingSecondsLeft = 0;
            // _isPending stays true -> button shows "Pending - Waiting for network"
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
  // CONNECTIVITY HANDLER
  // ----------------------------------------------------------
  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    final bool hasConnection =
        results.any((r) => r != ConnectivityResult.none);

    if (!hasConnection || !mounted) return;

    final uploaded = await _syncPendingQueueToBackend();

    if (uploaded > 0) {
      _showSnack(
        "Network restored. $uploaded pending attendance(s) sent to admin.",
        Colors.green,
      );
    }
  }

  // ----------------------------------------------------------
  // ----------------------------------------------------------
// ONLINE CHECK-IN (DIRECT ATTENDANCE API)
// ----------------------------------------------------------


Future<void> _sendOnlineAttendance({int retry = 0}) async {
  final token = await _getToken();
  if (token == null) {
    _showSnack("Not authorized", Colors.redAccent);
    return;
  }

  if (_lastCapturedImage == null) {
    _showSnack("Please capture photo first.", Colors.redAccent);
    return;
  }

  try {
    final uri = Uri.parse('$apiBaseUrl/api/v1/attendance/checkin');

    final req = http.MultipartRequest('POST', uri);
    req.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';

    req.fields['location'] = _addressText;
    if (_currentLat != null) req.fields['lat'] = _currentLat!.toString();
    if (_currentLng != null) req.fields['lng'] = _currentLng!.toString();

    req.files.add(await http.MultipartFile.fromPath(
      'attendanceImage',
      _lastCapturedImage!.path,
    ));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    print("CHECKIN STATUS = ${res.statusCode}");
    print("CHECKIN BODY = ${res.body}");

    // SUCCESS
    if (res.statusCode == 200 || res.statusCode == 201) {
      _showSnack("Checked in successfully!", Colors.green);
      return;
    }

    // SERVER reachable but error (4xx/5xx)
    _showSnack(
        jsonDecode(res.body)['message'] ?? "Server error", Colors.orange);
    return;

  } on SocketException catch (_) {
  print("🌐 No Internet - Retry #$retry");

  if (retry < _maxRetries) {
    await Future.delayed(const Duration(seconds: 30));
    return _sendOnlineAttendance(retry: retry + 1);
  }

  // 🔴 2 retries fail -> local pending + backend pending sync
  await _savePendingAttendanceLocally();
  _showSnack(
    "Network issue. Marked as pending for admin.",
    Colors.orange,
  );

  // Yahin se try karo backend pending API ko call karne ka
  // (agar abhi tak net aa gaya ho to turant admin me dikhega)
  await _syncPendingAttendance();

  return;
}
 catch (e) {
    _showSnack("Unexpected error: $e", Colors.redAccent);
  }
}

Future<void> _savePendingAttendanceLocally() async {
  final prefs = await SharedPreferences.getInstance();

  final data = {
    "workerId": _userId,
    "location": _addressText,
    "dateTime": DateTime.now().toIso8601String(),
    "imagePath": _lastCapturedImage!.path
  };

  List<String> list = prefs.getStringList("pending_attendance") ?? [];
  list.add(jsonEncode(data));
  await prefs.setStringList("pending_attendance", list);

  print("📌 Pending attendance saved locally.");
}

Future<void> _syncPendingAttendance() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> list = prefs.getStringList("pending_attendance") ?? [];

  if (list.isEmpty) {
    print("✅ No pending attendance to sync.");
    return;
  }

  final token = await _getToken();
  if (token == null) {
    print("⚠️ No token found, cannot sync pending attendance.");
    return;
  }

  final uri = Uri.parse(
    '$apiBaseUrl/api/v1/attendance/supervisor/checkin-pending',
  );
  final remaining = <String>[];

  for (final item in list) {
    final data = jsonDecode(item);

    try {
      final imagePath = data["imagePath"] as String?;

      if (imagePath == null || !File(imagePath).existsSync()) {
        // Image file missing → skip this record permanently
        print("⚠️ Image file missing for pending item, dropping it.");
        continue;
      }

      final req = http.MultipartRequest("POST", uri);
      req.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';

      req.fields["workerId"] = data["workerId"];
      req.fields["location"] = data["location"] ?? "";
      req.fields["dateTime"] = data["dateTime"] ?? "";

      req.files.add(
        await http.MultipartFile.fromPath(
          "attendanceImage",
          imagePath,
        ),
      );

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      print(
          "📤 Sync pending -> status: ${res.statusCode}, body: ${res.body}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        // server ne accept nahi kiya → queue me wapas daal do
        remaining.add(item);
      }
    } catch (e) {
      print("❌ Error syncing pending attendance: $e");
      remaining.add(item); // network ya koi aur error → next time try karenge
    }
  }

  await prefs.setStringList("pending_attendance", remaining);

  if (remaining.isEmpty) {
    print("🎉 All pending attendance synced successfully!");
  } else {
    print("⌛ ${remaining.length} pending records still in queue.");
  }
}


  // ----------------------------------------------------------
  // BUTTON HANDLER
  // ----------------------------------------------------------
  void _confirmCheckIn() async {
    if (_lastCapturedImage == null) {
      _showSnack("Please capture photo first.", Colors.redAccent);
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    final bool hasInternet = connectivity != ConnectivityResult.none;

    if (!hasInternet) {
      // ---------- OFFLINE FLOW ----------
      _offlineTryCount++;

      if (_offlineTryCount == 1) {
        // 1st time offline -> save record + countdown, then back to "Confirm Check In"
        await _addPendingRecordToStorage();
        _showSnack(
          "No internet. Attendance stored as pending (1st attempt).",
          Colors.orange,
        );
        _startPendingCycle(allowReset: true);
      } else {
        // 2nd time (or more) offline -> countdown, then stuck pending until network
        _showSnack(
          "No internet again. Check-in will stay pending until network is back.",
          Colors.deepOrange,
        );
        _startPendingCycle(allowReset: false);
      }
      return;
    }

    // ---------- ONLINE FLOW ----------
    _offlineTryCount = 0; // reset tries when internet is available
    await _sendOnlineAttendance();
  }

  // ----------------------------------------------------------
  // PENDING DETAILS DIALOG
  // ----------------------------------------------------------
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
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  ],
                ),
              ),
              const SizedBox(height: 8),
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