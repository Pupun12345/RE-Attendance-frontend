// lib/screens/shared/selfie_checkin_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:smartcare_app/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SelfieCheckInScreen extends StatefulWidget {
  const SelfieCheckInScreen({super.key});

  @override
  State<SelfieCheckInScreen> createState() => _SelfieCheckInScreenState();
}

class _SelfieCheckInScreenState extends State<SelfieCheckInScreen> {
  String dateTime = "";
  String location = "Fetching location...";
  String coordsText = "Fetching coordinates...";
  final Color themeBlue = const Color(0xFF0B3B8C);
  File? selfieImage;
  Position? _currentPosition;
  bool _isLoading = false;
  String _userName = "Unknown";

  bool _isPendingMode = false;
  bool _isRetrying = false;
  int _retrySeconds = 0;
  Timer? _retryTimer;

  final String _apiUrl = apiBaseUrl;

  @override
  void initState() {
    super.initState();
    updateDateTime();
    fetchLocation();
    _loadUserData();
    _checkPendingData();

    _checkConnectivityAndSync();

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _attemptSync();
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivityAndSync() async {
    var results = await Connectivity().checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      _attemptSync();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _userName = prefs.getString('userName') ?? "Unknown");
  }

  Future<void> _checkPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    String? pending = prefs.getString("pending_checkin");
    if (pending != null) {
      final jsonData = jsonDecode(pending);
      bool needsAdmin = jsonData['needsAdminApproval'] ?? false;

      setState(() {
        _isPendingMode = true;
        selfieImage = File(jsonData['imagePath']);
        coordsText = "Lat: ${jsonData['lat']}, Lng: ${jsonData['lng']}";
        location = jsonData['location'];
        dateTime = jsonData['displayTime'] ?? "Pending Time";

        if (needsAdmin) {
          _retrySeconds = 60;
        }
      });
    }
  }

  Future<void> _attemptSync() async {
    if (!_isPendingMode) return;

    final prefs = await SharedPreferences.getInstance();
    String? pending = prefs.getString("pending_checkin");
    if (pending == null) return;

    final pendingData = jsonDecode(pending);
    File img = File(pendingData['imagePath']);
    bool needsAdmin = pendingData['needsAdminApproval'] ?? false;

    await _uploadData(img, pendingData['lat'], pendingData['lng'],
        pendingData['dateTime'], true, needsAdmin);
  }

  void updateDateTime() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      setState(() {
        dateTime =
            "${now.day.toString().padLeft(2, '0')} ${_month(now.month)} ${now.year} ${_formatTime(now)}";
      });
    });
  }

  String _month(int m) => [
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
      ][m - 1];

  String _formatTime(DateTime now) {
    int hour = now.hour;
    String ampm = hour >= 12 ? "PM" : "AM";
    hour = hour % 12 == 0 ? 12 : hour % 12;
    return "$hour:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} $ampm";
  }

  Future<void> fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _currentPosition = pos;
      setState(() {
        coordsText =
            "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
      });

      List<Placemark> places =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      Placemark place = places.first;
      setState(() {
        location = "${place.locality ?? ""}, ${place.subLocality ?? ""}";
      });
    } catch (e) {}
  }

  Future<bool> _checkInternet() async {
    var results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> openCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => selfieImage = File(picked.path));
    }
  }

  Future<void> _uploadData(File img, double lat, double lng, String dt,
      bool isRetry, bool sendToAdminQueue) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final role = prefs.getString("role");
      String endpoint = sendToAdminQueue
          ? "$_apiUrl/api/v1/attendance/checkin-pending"
          : "$_apiUrl/api/v1/attendance/checkin";

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers["Authorization"] = "Bearer $token";

      request.fields["location"] = "$lat,$lng";
      request.fields["dateTime"] =
          isRetry ? dt : DateTime.now().toIso8601String();

      request.files.add(await http.MultipartFile.fromPath(
        'attendanceImage',
        img.path,
        contentType: MediaType("image", "jpeg"),
      ));

      var resp = await request.send();
      var res = await http.Response.fromStream(resp);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _retryTimer?.cancel();
        await prefs.remove("pending_checkin");

        setState(() {
          _isPendingMode = false;
          _isRetrying = false;
        });

        String msg = sendToAdminQueue
            ? "Sent to Admin for Approval (Network Delay)"
            : "Checked In Successfully!";

        _showSuccess(msg);
        if (mounted) Navigator.pop(context);
      } else {
        _retryTimer?.cancel();
        final responseData = jsonDecode(res.body);
        _showError(responseData['message'] ?? "Check-in failed");
      }
    } catch (e) {
      if (!isRetry) {
        _startOneMinuteTimer();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startOneMinuteTimer() {
    _savePending(needsAdminApproval: false);

    setState(() {
      _isRetrying = true;
      _retrySeconds = 0;
    });

    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _retrySeconds++;
      });

      if (_retrySeconds % 5 == 0) {
        _checkConnectivityAndSync();
      }

      if (_retrySeconds >= 60) {
        timer.cancel();
        setState(() => _isRetrying = false);
        _savePending(needsAdminApproval: true);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Network timeout. Request saved for Admin Approval."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ));
      }
    });
  }

  Future<void> confirmCheckIn() async {
    if (selfieImage == null) return;
    if (_currentPosition == null) return;

    await _uploadData(selfieImage!, _currentPosition!.latitude,
        _currentPosition!.longitude, "", false, false);
  }

  Future<void> _savePending({required bool needsAdminApproval}) async {
    if (selfieImage == null) return;

    // ✅ FIX: Move file from Cache to Permanent Storage
    final directory = await getApplicationDocumentsDirectory();
    final String fileName =
        'checkin_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = path.join(directory.path, fileName);

    // Copy the file
    final File newImage = await selfieImage!.copy(newPath);

    final prefs = await SharedPreferences.getInstance();
    final data = {
      "imagePath": newImage.path, // ✅ Save the PERMANENT path
      "lat": _currentPosition!.latitude,
      "lng": _currentPosition!.longitude,
      "dateTime": DateTime.now().toIso8601String(),
      "displayTime": dateTime,
      "location": location,
      "needsAdminApproval": needsAdminApproval,
    };

    await prefs.setString("pending_checkin", jsonEncode(data));

    setState(() {
      _isPendingMode = true;
      selfieImage = newImage; // Update UI to refer to the safe file
    });

    if (!needsAdminApproval && _retrySeconds == 0) {
      _showError("No Internet. Retrying for 1 minute...");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext ctx) {
    bool hasImage = selfieImage != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(ctx),
        ),
        title:
            const Text("Selfie Punch", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.access_time),
              const SizedBox(width: 8),
              Text(dateTime)
            ]),
            Row(children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: 8),
              Text(_userName)
            ]),
            const Spacer(),
            if (hasImage)
              ClipOval(
                  child: Image.file(selfieImage!,
                      height: 160, width: 160, fit: BoxFit.cover)),
            if (_isRetrying) ...[
              const SizedBox(height: 20),
              Text("Retrying connection... (${60 - _retrySeconds}s left)",
                  style: const TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                  value: _retrySeconds / 60, color: Colors.orange),
            ],
            const SizedBox(height: 20),
            Row(children: [
              const Icon(Icons.gps_fixed),
              const SizedBox(width: 8),
              Expanded(child: Text(coordsText))
            ]),
            Row(children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(location))
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _isRetrying
                    ? null
                    : (_isPendingMode
                        ? _attemptSync
                        : (hasImage ? confirmCheckIn : openCamera)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isPendingMode
                            ? "Pending (Tap to Sync)"
                            : (hasImage ? "Confirm Check-In" : "Take Photo"),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
