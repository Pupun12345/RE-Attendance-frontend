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


  bool _isPending = false;


  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  final String _apiUrl = apiBaseUrl;

  @override
  void initState() {
    super.initState();
    updateDateTime();
    fetchLocation();
    _loadUserData();
    _loadPendingIfAny();

    // 🔹 FIX: Wrap listener to handle List<ConnectivityResult>
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
          final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
          _handleConnectivityChange(result);
        });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? "Unknown";
    });
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
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
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


  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();

    return result != ConnectivityResult.none;
  }

  // 🧾 Main confirm flow
  Future<void> confirmCheckout() async {
    if (selfieImage == null) {
      _showError("Selfie is required");
      return;
    }
    if (_currentPosition == null) {
      _showError("Location is required. Please wait.");
      return;
    }

    final hasNet = await _hasInternet();

    if (!hasNet) {

      await _savePending();
      return;
    }


    await _uploadCheckout(
      imageFile: selfieImage!,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      dt: dateTime,
      fromRetry: false,
    );
  }


  Future<void> _uploadCheckout({
    required File imageFile,
    required double lat,
    required double lng,
    required String dt,
    required bool fromRetry,
  }) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_apiUrl/api/v1/attendance/checkout"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['location'] = "$lat,$lng";
      request.fields['dateTime'] = dt;

      request.files.add(
        await http.MultipartFile.fromPath(
          'attendanceImage',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await prefs.remove('pending_checkout');
        setState(() => _isPending = false);

        _showSuccess(fromRetry
            ? "Pending Check-Out uploaded successfully!"
            : "Checked Out Successfully!");

        if (!mounted) return;
        Navigator.pop(context);
      } else {
        if (!fromRetry) {
          await _savePending();
        }
        _showError(responseData['message'] ?? "Check-out failed");
      }
    } catch (e) {
      if (!fromRetry) {
        await _savePending();
      }
      _showError("Could not connect to server.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _savePending() async {
    if (selfieImage == null || _currentPosition == null) return;

    final prefs = await SharedPreferences.getInstance();

    final pendingData = {
      "imagePath": selfieImage!.path,
      "lat": _currentPosition!.latitude,
      "lng": _currentPosition!.longitude,
      "dateTime": dateTime,
      "location": location,
      "coordsText": coordsText,
      "userName": _userName,
    };

    await prefs.setString('pending_checkout', jsonEncode(pendingData));

    setState(() {
      _isPending = true;
    });

    _showError("No internet. Check-Out marked as Pending.");
  }


  Future<void> _loadPendingIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('pending_checkout');
    if (data == null) return;

    final jsonData = jsonDecode(data);

    setState(() {
      _isPending = true;
      selfieImage = File(jsonData['imagePath']);
      coordsText = jsonData['coordsText'] ?? coordsText;
      location = jsonData['location'] ?? location;
      dateTime = jsonData['dateTime'] ?? dateTime;
      _userName = jsonData['userName'] ?? _userName;
    });
  }


  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) return;
    if (!_isPending) return;

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('pending_checkout');
    if (data == null) return;

    final jsonData = jsonDecode(data);
    final img = File(jsonData['imagePath']);

    await _uploadCheckout(
      imageFile: img,
      lat: (jsonData['lat'] as num).toDouble(),
      lng: (jsonData['lng'] as num).toDouble(),
      dt: jsonData['dateTime'],
      fromRetry: true,
    );
  }

  // 🪪 Pending detail card
  void _showPendingDetailsCard() {
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
                "Pending Check-Out",
                style: TextStyle(
                  color: themeBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (selfieImage != null)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: FileImage(selfieImage!),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateTime,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      coordsText,
                      style: const TextStyle(fontSize: 13),
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
                      location,
                      style: const TextStyle(fontSize: 14),
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

  // Snackbar helpers
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

            if (hasImage) const SizedBox(height: 20),

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
                onPressed: _isLoading
                    ? null
                    : (_isPending
                    ? _showPendingDetailsCard
                    : (hasImage ? confirmCheckout : openCamera)),
                icon: _isLoading
                    ? Container()
                    : Icon(
                  _isPending
                      ? Icons.hourglass_bottom
                      : (hasImage ? Icons.check : Icons.camera_alt),
                  size: 22,
                ),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isPending
                      ? "Pending"
                      : (hasImage ? "Confirm Clock-Out" : "Take Photo"),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _isPending ? Colors.orange.shade700 : themeBlue,
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
