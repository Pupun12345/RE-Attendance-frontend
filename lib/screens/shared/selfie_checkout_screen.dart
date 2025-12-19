// lib/screens/shared/selfie_checkout_screen.dart
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

class SelfieCheckOutScreen extends StatefulWidget {
  const SelfieCheckOutScreen({super.key});

  @override
  State<SelfieCheckOutScreen> createState() => _SelfieCheckOutScreenState();
}

class _SelfieCheckOutScreenState extends State<SelfieCheckOutScreen> {
  String dateTime = "";
  String location = "Fetching location...";
  String coordsText = "Fetching coordinates...";
  final Color themeBlue = const Color(0xFF0B3B8C);
  File? selfieImage;
  Position? _currentPosition;
  bool _isLoading = false;
  String _userName = "Unknown";

  // 🔹 Timer Logic State
  bool _isPendingMode = false;
  bool _isRetrying = false;
  int _retrySeconds = 0;
  Timer? _retryTimer;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final String _apiUrl = apiBaseUrl;

  @override
  void initState() {
    super.initState();
    updateDateTime();
    fetchLocation();
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
  void dispose() {
    _connectivitySub?.cancel();
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
    setState(() {
      _userName = prefs.getString('userName') ?? "Unknown";
    });
  }

  Future<void> _checkPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    String? pending = prefs.getString("pending_checkout");
    if (pending != null) {
      final jsonData = jsonDecode(pending);
      bool needsAdmin = jsonData['needsAdminApproval'] ?? false;

      setState(() {
        _isPendingMode = true;
        selfieImage = File(jsonData['imagePath']);
        coordsText = jsonData['coordsText'] ?? coordsText;
        location = jsonData['location'] ?? location;
        dateTime = jsonData['displayTime'] ?? dateTime;

        if (needsAdmin) {
          _retrySeconds = 60;
        }
      });
    }
  }

  Future<void> _attemptSync() async {
    if (!_isPendingMode) return;

    final prefs = await SharedPreferences.getInstance();
    String? pending = prefs.getString("pending_checkout");
    if (pending == null) return;

    final pendingData = jsonDecode(pending);
    File img = File(pendingData['imagePath']);
    bool needsAdmin = pendingData['needsAdminApproval'] ?? false;

    await _uploadCheckout(
        imageFile: img,
        lat: (pendingData['lat'] as num).toDouble(),
        lng: (pendingData['lng'] as num).toDouble(),
        dt: pendingData['dateTime'],
        isRetry: true,
        sendToAdminQueue: needsAdmin);
  }

  void updateDateTime() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      setState(() {
        dateTime = "${now.day.toString().padLeft(2, '0')} "
            "${_month(now.month)} ${now.year} "
            "${_formatTime(now)}";
      });
    });
  }

  String _month(int m) {
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

  String _formatTime(DateTime now) {
    int hour = now.hour;
    String ampm = hour >= 12 ? "PM" : "AM";
    hour = hour % 12 == 0 ? 12 : hour % 12;
    String minute = now.minute.toString().padLeft(2, '0');
    String second = now.second.toString().padLeft(2, '0');
    return "$hour:$minute:$second $ampm";
  }

  Future<void> fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        location = "GPS disabled";
        coordsText = "GPS disabled";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          location = "Location permission denied";
          coordsText = "Permission denied";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        location = "Permission blocked";
        coordsText = "Permission blocked";
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = pos;

      if (mounted) {
        setState(() {
          coordsText =
              "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        });
      }

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );

        if (!mounted) return;

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String city = place.locality ?? place.subAdministrativeArea ?? "";
          String area = place.thoroughfare ?? place.subLocality ?? "";

          setState(() {
            if (area.isEmpty && city.isEmpty) {
              location = "Unknown Location";
            } else if (area.isEmpty) {
              location = city;
            } else {
              location = "$area, $city";
            }
          });
        } else {
          setState(() {
            location = "Address not found";
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            location =
                "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          location = "Error fetching location.";
          coordsText = "Error fetching coordinates.";
        });
      }
    }
  }

  Future<void> openCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          selfieImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError("Camera not available on this device.");
    }
  }

  Future<void> confirmCheckout() async {
    if (selfieImage == null) {
      _showError("Selfie is required");
      return;
    }
    if (_currentPosition == null) {
      _showError("Location is required. Please wait.");
      return;
    }

    await _uploadCheckout(
        imageFile: selfieImage!,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        dt: "",
        isRetry: false,
        sendToAdminQueue: false);
  }

  Future<void> _uploadCheckout({
    required File imageFile,
    required double lat,
    required double lng,
    required String dt,
    required bool isRetry,
    required bool sendToAdminQueue,
  }) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final role = prefs.getString('role');

      String endpoint= sendToAdminQueue
            ? "$_apiUrl/api/v1/attendance/checkout-pending"
            : "$_apiUrl/api/v1/attendance/checkout";

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['location'] = "$lat,$lng";
      request.fields['dateTime'] =
          isRetry ? dt : DateTime.now().toIso8601String();

      request.files.add(
        await http.MultipartFile.fromPath(
          'attendanceImage',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _retryTimer?.cancel();
        await prefs.remove('pending_checkout');

        setState(() {
          _isPendingMode = false;
          _isRetrying = false;
        });

        String msg = sendToAdminQueue
            ? "Sent to Admin for Approval (Network Delay)"
            : "Checked Out Successfully!";

        _showSuccess(msg);
        if (mounted) Navigator.pop(context);
      } else {
        _retryTimer?.cancel();
        final responseData = jsonDecode(response.body);
        _showError(responseData['message'] ?? "Check-out failed");
      }
    } catch (e) {
      if (!isRetry) {
        _startOneMinuteTimer();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _savePending({required bool needsAdminApproval}) async {
    if (selfieImage == null) return;

    // ✅ FIX: Move file from Cache to Permanent Storage
    final directory = await getApplicationDocumentsDirectory();
    final String fileName =
        'checkout_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = path.join(directory.path, fileName);

    final File newImage = await selfieImage!.copy(newPath);

    final prefs = await SharedPreferences.getInstance();
    final data = {
      "imagePath": newImage.path, // ✅ Save the PERMANENT path
      "lat": _currentPosition!.latitude,
      "lng": _currentPosition!.longitude,
      "dateTime": DateTime.now().toIso8601String(),
      "displayTime": dateTime,
      "location": location,
      "coordsText": coordsText,
      "userName": _userName,
      "needsAdminApproval": needsAdminApproval,
    };

    await prefs.setString('pending_checkout', jsonEncode(data));

    setState(() {
      _isPendingMode = true;
      selfieImage = newImage;
    });

    if (!needsAdminApproval && _retrySeconds == 0) {
      _showError("No Internet. Retrying for 1 minute...");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = selfieImage != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Selfie Punch Out",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.black),
                const SizedBox(width: 8),
                Text(dateTime, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 20),
                const SizedBox(width: 8),
                Text(_userName, style: const TextStyle(fontSize: 16)),
              ],
            ),

            const Spacer(),

            if (hasImage)
              Center(
                child: ClipOval(
                  child: Image.file(
                    selfieImage!,
                    height: 160,
                    width: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // 🔹 Show Retry Progress
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

            Row(
              children: [
                const Icon(Icons.gps_fixed, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    coordsText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _isRetrying
                    ? null
                    : (_isPendingMode
                        ? _attemptSync
                        : (hasImage ? confirmCheckout : openCamera)),
                icon: _isLoading
                    ? Container()
                    : Icon(
                        _isPendingMode
                            ? Icons.hourglass_bottom
                            : (hasImage ? Icons.check : Icons.camera_alt),
                        size: 22,
                      ),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isPendingMode
                            ? "Pending (Tap to Sync)"
                            : (hasImage ? "Confirm Clock-Out" : "Take Photo"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isPendingMode ? Colors.orange.shade700 : themeBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}