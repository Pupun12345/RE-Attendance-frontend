// NEW SELFIE CHECK IN WITH PENDING MODE SUPPORT
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

  final String _apiUrl = apiBaseUrl;

  @override
  void initState() {
    super.initState();
    updateDateTime();
    fetchLocation();
    _loadUserData();
    _checkPendingData();
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _retryPendingUpload();
      }
    });
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
      setState(() {
        _isPendingMode = true;
        selfieImage = File(jsonData['imagePath']);
        coordsText =
        "Lat: ${jsonData['lat']}, Lng: ${jsonData['lng']}";
        location = jsonData['location'];
        dateTime = jsonData['dateTime'];
      });
    }
  }

  Future<void> _retryPendingUpload() async {
    final prefs = await SharedPreferences.getInstance();
    String? pending = prefs.getString("pending_checkin");
    if (pending == null) return;

    final pendingData = jsonDecode(pending);
    File img = File(pendingData['imagePath']);

    await _uploadData(
      img,
      pendingData['lat'],
      pendingData['lng'],
      pendingData['dateTime'],
      true,
    );
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

  String _month(int m) =>
      ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m-1];

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
        desiredAccuracy: LocationAccuracy.best,
      );
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
    return await Connectivity().checkConnectivity() != ConnectivityResult.none;
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
      bool retryMode) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_apiUrl/api/v1/attendance/checkin"),
      );
      request.headers["Authorization"] = "Bearer $token";

      request.fields["location"] = "$lat,$lng";
      request.fields["dateTime"] = dt;

      request.files.add(await http.MultipartFile.fromPath(
        'attendanceImage',
        img.path,
        contentType: MediaType("image", "jpeg"),
      ));

      var resp = await request.send();
      var res = await http.Response.fromStream(resp);

      if (res.statusCode == 200) {
        prefs.remove("pending_checkin");
        setState(() => _isPendingMode = false);
        _showSuccess(retryMode ? "Pending Check-in Uploaded!" : "Checked In!");
        Navigator.pop(context);
      } else {
        if (!retryMode) _savePending();
      }
    } catch (e) {
      if (!retryMode) _savePending();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> confirmCheckIn() async {
    if (selfieImage == null) return;
    if (_currentPosition == null) return;

    bool hasNet = await _checkInternet();

    if (hasNet) {
      await _uploadData(
        selfieImage!,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        dateTime,
        false,
      );
    } else {
      _savePending();
    }
  }

  Future<void> _savePending() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      "imagePath": selfieImage!.path,
      "lat": _currentPosition!.latitude,
      "lng": _currentPosition!.longitude,
      "dateTime": dateTime,
      "location": location,
    };
    prefs.setString("pending_checkin", jsonEncode(data));

    setState(() => _isPendingMode = true);
    _showError("No Internet → Marked as Pending");
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ));

  void _showSuccess(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
      ));

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
        centerTitle: true,
        title: const Text(
          "Selfie Punch",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.access_time),
              const SizedBox(width: 8),
              Text(dateTime),
            ]),
            Row(children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: 8),
              Text(_userName),
            ]),

            const Spacer(),

            if (hasImage)
              ClipOval(
                child: Image.file(
                  selfieImage!,
                  height: 160,
                  width: 160,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            Row(children: [
              const Icon(Icons.gps_fixed),
              const SizedBox(width: 8),
              Expanded(child: Text(coordsText)),
            ]),
            Row(children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(location)),
            ]),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_isPendingMode
                    ? _retryPendingUpload
                    : (hasImage ? confirmCheckIn : openCamera)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isPendingMode
                      ? "Pending..."
                      : (hasImage ? "Confirm Check-In" : "Check In"),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
