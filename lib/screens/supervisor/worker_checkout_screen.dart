// lib/screens/supervisor/worker_checkout_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

class WorkerCheckOutScreen extends StatefulWidget {
  final String workerId;
  final String workerName;

  const WorkerCheckOutScreen({
    Key? key, 
    required this.workerId, 
    required this.workerName
  }) : super(key: key);

  @override
  State<WorkerCheckOutScreen> createState() => _WorkerCheckOutScreenState();
}

class _WorkerCheckOutScreenState extends State<WorkerCheckOutScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  String _timeString = "";
  Timer? _timer;
  String _locationText = "Fetching location...";
  File? _lastCapturedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startClock();
    _determinePositionAndListen();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
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
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[m - 1];
  }

  Future<void> _determinePositionAndListen() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationText = "GPS not enabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;
      setState(() => _locationText = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}");

    } catch (e) {
      if (!mounted) return;
      setState(() => _locationText = "Unable to fetch location");
    }
  }

  Future<void> _openCameraAndCheckOut() async {
    if (_locationText.contains("Fetching") || _locationText.contains("Unable") || _locationText.contains("GPS")) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wait for location..."), backgroundColor: Colors.orange));
      return;
    }

    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 80);
      if (picked == null) return;

      setState(() {
        _lastCapturedImage = File(picked.path);
        _isSubmitting = true;
      });

      // --- API CALL ---
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      var request = http.MultipartRequest('POST', Uri.parse("$apiBaseUrl/api/v1/attendance/supervisor/checkout"));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['workerId'] = widget.workerId;
      request.fields['location'] = _locationText;

      request.files.add(await http.MultipartFile.fromPath(
        'attendanceImage', 
        picked.path,
        contentType: MediaType('image', 'jpeg')
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
         if(!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Worker Checked Out Successfully!"), backgroundColor: Colors.green));
         Navigator.pop(context); // Go back
      } else {
         final respData = jsonDecode(response.body);
         if(!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(respData['message'] ?? "Failed"), backgroundColor: Colors.red));
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error uploading data"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Worker Check Out",
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
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 20, color: Colors.black87),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.workerName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (_lastCapturedImage != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_lastCapturedImage!, height: 220, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 100),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationText,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 58,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _openCameraAndCheckOut,
                  icon: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.camera_alt, size: 22, color: Colors.white),
                  label: Text(
                    _isSubmitting ? "Uploading..." : "Check Out",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
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