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
<<<<<<< HEAD
  String _fullAddress = ""; // ✅ Complete address for API
=======
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
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
<<<<<<< HEAD
        _fullAddress = jsonData['fullAddress'] ?? ""; // ✅ Restore full address
=======
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
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
<<<<<<< HEAD
      imageFile: img,
      lat: (pendingData['lat'] as num).toDouble(),
      lng: (pendingData['lng'] as num).toDouble(),
      address: pendingData['fullAddress'] ?? "", // ✅ Pass full address
      dt: pendingData['dateTime'],
      isRetry: true,
      sendToAdminQueue: needsAdmin,
    );
=======
        imageFile: img,
        lat: (pendingData['lat'] as num).toDouble(),
        lng: (pendingData['lng'] as num).toDouble(),
        dt: pendingData['dateTime'],
        isRetry: true,
        sendToAdminQueue: needsAdmin);
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
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

<<<<<<< HEAD
  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${_formatTime(dt)}";
  }

=======
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
  Future<void> fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
<<<<<<< HEAD
        location = "Location services disabled";
        coordsText = "Enable GPS";
=======
        location = "GPS disabled";
        coordsText = "GPS disabled";
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          location = "Location permission denied";
<<<<<<< HEAD
          coordsText = "Allow location access";
=======
          coordsText = "Permission denied";
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
<<<<<<< HEAD
        location = "Permission permanently denied";
        coordsText = "Check app settings";
=======
        location = "Permission blocked";
        coordsText = "Permission blocked";
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
<<<<<<< HEAD
        desiredAccuracy: LocationAccuracy.high, // ✅ High accuracy
=======
        desiredAccuracy: LocationAccuracy.high,
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = pos;

      if (mounted) {
        setState(() {
          coordsText =
<<<<<<< HEAD
          "Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}";
        });
      }

      // ✅ Get detailed address
=======
              "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        });
      }

>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );

        if (!mounted) return;

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
<<<<<<< HEAD

          // ✅ Build complete address
          List<String> addressParts = [];

          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty) {
            addressParts.add(place.subAdministrativeArea!);
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            addressParts.add(place.postalCode!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }

          String fullAddr = addressParts.join(", ");
          String displayAddr =
              "${place.locality ?? "Unknown"}, ${place.subLocality ?? ""}";

          setState(() {
            _fullAddress =
            fullAddr.isNotEmpty ? fullAddr : "Address unavailable";
            location = displayAddr.isNotEmpty ? displayAddr : "Location found";
=======
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
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
          });
        } else {
          setState(() {
            location = "Address not found";
<<<<<<< HEAD
            _fullAddress = "$pos.latitude,$pos.longitude";
=======
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            location =
<<<<<<< HEAD
            "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
            _fullAddress = "${pos.latitude},${pos.longitude}";
=======
                "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
<<<<<<< HEAD
          location = "Failed to fetch location";
          coordsText = "Error: ${e.toString()}";
=======
          location = "Error fetching location.";
          coordsText = "Error fetching coordinates.";
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
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
<<<<<<< HEAD
      _showError("Please take a selfie first");
      return;
    }
    if (_currentPosition == null) {
      _showError("Location not available. Please wait...");
      fetchLocation(); // ✅ Retry fetching location
      return;
    }

    if (_fullAddress.isEmpty) {
      _showError("Address not available. Please wait...");
      fetchLocation(); // ✅ Retry fetching address
=======
      _showError("Selfie is required");
      return;
    }
    if (_currentPosition == null) {
      _showError("Location is required. Please wait.");
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
      return;
    }

    await _uploadCheckout(
<<<<<<< HEAD
      imageFile: selfieImage!,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      address: _fullAddress, // ✅ Send full address
      dt: "",
      isRetry: false,
      sendToAdminQueue: false,
    );
=======
        imageFile: selfieImage!,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        dt: "",
        isRetry: false,
        sendToAdminQueue: false);
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
  }

  Future<void> _uploadCheckout({
    required File imageFile,
    required double lat,
    required double lng,
<<<<<<< HEAD
    required String address, // ✅ Accept address parameter
=======
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
    required String dt,
    required bool isRetry,
    required bool sendToAdminQueue,
  }) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final role = prefs.getString('role');

<<<<<<< HEAD
      String endpoint = sendToAdminQueue
          ? "$_apiUrl/api/v1/attendance/checkout-pending"
          : "$_apiUrl/api/v1/attendance/checkout";

      // ✅ Print Request Start Time
      final requestStartTime = DateTime.now();
      print("\n╔════════════════════════════════════════════╗");
      print("║       CHECKOUT API REQUEST START           ║");
      print("╚════════════════════════════════════════════╝");
      print("⏰ Request Time: ${_formatDateTime(requestStartTime)}");
      print("🔗 Endpoint: $endpoint");
      print("📍 Location: $address");
      print("📌 Coordinates: ($lat, $lng)");
      print("📅 DateTime: ${isRetry ? dt : DateTime.now().toIso8601String()}");
      print("🔄 Is Retry: $isRetry");
      print("⚠️  Admin Queue: $sendToAdminQueue");
      print("🖼️  Image Path: ${imageFile.path}");
      print("═══════════════════════════════════════════════\n");
=======
      String endpoint= sendToAdminQueue
            ? "$_apiUrl/api/v1/attendance/checkout-pending"
            : "$_apiUrl/api/v1/attendance/checkout";
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      request.headers['Authorization'] = 'Bearer $token';
<<<<<<< HEAD

      // ✅ Send proper location format
      request.fields['location'] = address.isNotEmpty ? address : "$lat,$lng";
      request.fields['latitude'] = lat.toString();
      request.fields['longitude'] = lng.toString();
      request.fields['dateTime'] =
      isRetry ? dt : DateTime.now().toIso8601String();
=======
      request.fields['location'] = "$lat,$lng";
      request.fields['dateTime'] =
          isRetry ? dt : DateTime.now().toIso8601String();
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3

      request.files.add(
        await http.MultipartFile.fromPath(
          'attendanceImage',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

<<<<<<< HEAD
      print("📤 Sending checkout request...\n");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final requestEndTime = DateTime.now();
      final duration = requestEndTime.difference(requestStartTime);

      // ✅ Print Response Details
      print("\n╔════════════════════════════════════════════╗");
      print("║       CHECKOUT API RESPONSE RECEIVED       ║");
      print("╚════════════════════════════════════════════╝");
      print("⏰ Response Time: ${_formatDateTime(requestEndTime)}");
      print("⏱️  Duration: ${duration.inMilliseconds}ms");
      print("📊 Status Code: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");
      print("═══════════════════════════════════════════════\n");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ SUCCESS: Check-out completed successfully!\n");

=======
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
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
<<<<<<< HEAD
        print("❌ ERROR: Checkout failed with status ${response.statusCode}\n");

=======
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
        _retryTimer?.cancel();
        final responseData = jsonDecode(response.body);
        _showError(responseData['message'] ?? "Check-out failed");
      }
    } catch (e) {
<<<<<<< HEAD
      print("\n╔════════════════════════════════════════════╗");
      print("║       CHECKOUT API REQUEST FAILED          ║");
      print("╚════════════════════════════════════════════╝");
      print("❌ Error: $e");
      print("═══════════════════════════════════════════════\n");

=======
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
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

<<<<<<< HEAD
    // ✅ Move file from Cache to Permanent Storage
=======
    // ✅ FIX: Move file from Cache to Permanent Storage
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
    final directory = await getApplicationDocumentsDirectory();
    final String fileName =
        'checkout_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = path.join(directory.path, fileName);

    final File newImage = await selfieImage!.copy(newPath);

    final prefs = await SharedPreferences.getInstance();
    final data = {
<<<<<<< HEAD
      "imagePath": newImage.path,
      "lat": _currentPosition!.latitude,
      "lng": _currentPosition!.longitude,
      "fullAddress": _fullAddress, // ✅ Save full address
=======
      "imagePath": newImage.path, // ✅ Save the PERMANENT path
      "lat": _currentPosition!.latitude,
      "lng": _currentPosition!.longitude,
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
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
<<<<<<< HEAD
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: themeBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
=======
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
<<<<<<< HEAD
          "Selfie Check-Out",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.access_time, "Time", dateTime),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.person_outline, "Employee", _userName),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ✅ Selfie Section
              Center(
                child: Column(
                  children: [
                    if (hasImage)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: themeBlue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.file(
                            selfieImage!,
                            height: 180,
                            width: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          border: Border.all(color: themeBlue, width: 3),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),

                    if (_isRetrying) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sync,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Retrying... ${60 - _retrySeconds}s",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _retrySeconds / 60,
                                backgroundColor: Colors.orange[100],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.orange),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ✅ Location Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.gps_fixed, "Coordinates", coordsText),
                    const Divider(height: 24),
                    _buildInfoRow(
                        Icons.location_on_outlined, "Location", location),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ✅ Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _isRetrying
                      ? null
                      : (_isPendingMode
                      ? _attemptSync
                      : (hasImage ? confirmCheckout : openCamera)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isPendingMode ? Colors.orange.shade700 : themeBlue,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isLoading || _isRetrying ? 0 : 4,
                    shadowColor: _isPendingMode
                        ? Colors.orange.withOpacity(0.4)
                        : themeBlue.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPendingMode
                            ? Icons.sync
                            : (hasImage
                            ? Icons.logout
                            : Icons.camera_alt),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isPendingMode
                            ? "Retry Sync"
                            : (hasImage
                            ? "Confirm Check-Out"
                            : "Take Selfie"),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
=======
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
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
        ),
      ),
    );
  }
<<<<<<< HEAD

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: themeBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}





// // lib/screens/shared/selfie_checkout_screen.dart
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:async';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:http_parser/http_parser.dart';
// import 'package:smartcare_app/utils/constants.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
//
// class SelfieCheckOutScreen extends StatefulWidget {
//   const SelfieCheckOutScreen({super.key});
//
//   @override
//   State<SelfieCheckOutScreen> createState() => _SelfieCheckOutScreenState();
// }
//
// class _SelfieCheckOutScreenState extends State<SelfieCheckOutScreen> {
//   String dateTime = "";
//   String location = "Fetching location...";
//   String coordsText = "Fetching coordinates...";
//   final Color themeBlue = const Color(0xFF0B3B8C);
//   File? selfieImage;
//   Position? _currentPosition;
//   bool _isLoading = false;
//   String _userName = "Unknown";
//
//   // 🔹 Timer Logic State
//   bool _isPendingMode = false;
//   bool _isRetrying = false;
//   int _retrySeconds = 0;
//   Timer? _retryTimer;
//
//   StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
//   final String _apiUrl = apiBaseUrl;
//
//   @override
//   void initState() {
//     super.initState();
//     updateDateTime();
//     fetchLocation();
//     _loadUserData();
//     _checkPendingData();
//
//     _checkConnectivityAndSync();
//
//     _connectivitySub = Connectivity()
//         .onConnectivityChanged
//         .listen((List<ConnectivityResult> results) {
//       if (results.any((r) => r != ConnectivityResult.none)) {
//         _attemptSync();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _connectivitySub?.cancel();
//     _retryTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _checkConnectivityAndSync() async {
//     var results = await Connectivity().checkConnectivity();
//     if (results.any((r) => r != ConnectivityResult.none)) {
//       _attemptSync();
//     }
//   }
//
//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (!mounted) return;
//     setState(() {
//       _userName = prefs.getString('userName') ?? "Unknown";
//     });
//   }
//
//   Future<void> _checkPendingData() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? pending = prefs.getString("pending_checkout");
//     if (pending != null) {
//       final jsonData = jsonDecode(pending);
//       bool needsAdmin = jsonData['needsAdminApproval'] ?? false;
//
//       setState(() {
//         _isPendingMode = true;
//         selfieImage = File(jsonData['imagePath']);
//         coordsText = jsonData['coordsText'] ?? coordsText;
//         location = jsonData['location'] ?? location;
//         dateTime = jsonData['displayTime'] ?? dateTime;
//
//         if (needsAdmin) {
//           _retrySeconds = 60;
//         }
//       });
//     }
//   }
//
//   Future<void> _attemptSync() async {
//     if (!_isPendingMode) return;
//
//     final prefs = await SharedPreferences.getInstance();
//     String? pending = prefs.getString("pending_checkout");
//     if (pending == null) return;
//
//     final pendingData = jsonDecode(pending);
//     File img = File(pendingData['imagePath']);
//     bool needsAdmin = pendingData['needsAdminApproval'] ?? false;
//
//     await _uploadCheckout(
//         imageFile: img,
//         lat: (pendingData['lat'] as num).toDouble(),
//         lng: (pendingData['lng'] as num).toDouble(),
//         dt: pendingData['dateTime'],
//         isRetry: true,
//         sendToAdminQueue: needsAdmin);
//   }
//
//   void updateDateTime() {
//     Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       final now = DateTime.now();
//       setState(() {
//         dateTime = "${now.day.toString().padLeft(2, '0')} "
//             "${_month(now.month)} ${now.year} "
//             "${_formatTime(now)}";
//       });
//     });
//   }
//
//   String _month(int m) {
//     const months = [
//       "Jan",
//       "Feb",
//       "Mar",
//       "Apr",
//       "May",
//       "Jun",
//       "Jul",
//       "Aug",
//       "Sep",
//       "Oct",
//       "Nov",
//       "Dec"
//     ];
//     return months[m - 1];
//   }
//
//   String _formatTime(DateTime now) {
//     int hour = now.hour;
//     String ampm = hour >= 12 ? "PM" : "AM";
//     hour = hour % 12 == 0 ? 12 : hour % 12;
//     String minute = now.minute.toString().padLeft(2, '0');
//     String second = now.second.toString().padLeft(2, '0');
//     return "$hour:$minute:$second $ampm";
//   }
//
//   Future<void> fetchLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       setState(() {
//         location = "GPS disabled";
//         coordsText = "GPS disabled";
//       });
//       return;
//     }
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         setState(() {
//           location = "Location permission denied";
//           coordsText = "Permission denied";
//         });
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       setState(() {
//         location = "Permission blocked";
//         coordsText = "Permission blocked";
//       });
//       return;
//     }
//
//     try {
//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10),
//       );
//
//       _currentPosition = pos;
//
//       if (mounted) {
//         setState(() {
//           coordsText =
//               "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
//         });
//       }
//
//       try {
//         List<Placemark> placemarks = await placemarkFromCoordinates(
//           pos.latitude,
//           pos.longitude,
//         );
//
//         if (!mounted) return;
//
//         if (placemarks.isNotEmpty) {
//           Placemark place = placemarks[0];
//           String city = place.locality ?? place.subAdministrativeArea ?? "";
//           String area = place.thoroughfare ?? place.subLocality ?? "";
//
//           setState(() {
//             if (area.isEmpty && city.isEmpty) {
//               location = "Unknown Location";
//             } else if (area.isEmpty) {
//               location = city;
//             } else {
//               location = "$area, $city";
//             }
//           });
//         } else {
//           setState(() {
//             location = "Address not found";
//           });
//         }
//       } catch (e) {
//         if (mounted) {
//           setState(() {
//             location =
//                 "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           location = "Error fetching location.";
//           coordsText = "Error fetching coordinates.";
//         });
//       }
//     }
//   }
//
//   Future<void> openCamera() async {
//     try {
//       final pickedFile = await ImagePicker().pickImage(
//         source: ImageSource.camera,
//         preferredCameraDevice: CameraDevice.front,
//         imageQuality: 85,
//       );
//
//       if (pickedFile != null) {
//         setState(() {
//           selfieImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       _showError("Camera not available on this device.");
//     }
//   }
//
//   Future<void> confirmCheckout() async {
//     if (selfieImage == null) {
//       _showError("Selfie is required");
//       return;
//     }
//     if (_currentPosition == null) {
//       _showError("Location is required. Please wait.");
//       return;
//     }
//
//     await _uploadCheckout(
//         imageFile: selfieImage!,
//         lat: _currentPosition!.latitude,
//         lng: _currentPosition!.longitude,
//         dt: "",
//         isRetry: false,
//         sendToAdminQueue: false);
//   }
//
//   Future<void> _uploadCheckout({
//     required File imageFile,
//     required double lat,
//     required double lng,
//     required String dt,
//     required bool isRetry,
//     required bool sendToAdminQueue,
//   }) async {
//     setState(() => _isLoading = true);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//       final role = prefs.getString('role');
//
//       String endpoint= sendToAdminQueue
//             ? "$_apiUrl/api/v1/attendance/checkout-pending"
//             : "$_apiUrl/api/v1/attendance/checkout";
//
//       var request = http.MultipartRequest('POST', Uri.parse(endpoint));
//
//       request.headers['Authorization'] = 'Bearer $token';
//       request.fields['location'] = "$lat,$lng";
//       request.fields['dateTime'] =
//           isRetry ? dt : DateTime.now().toIso8601String();
//
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'attendanceImage',
//           imageFile.path,
//           contentType: MediaType('image', 'jpeg'),
//         ),
//       );
//
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         _retryTimer?.cancel();
//         await prefs.remove('pending_checkout');
//
//         setState(() {
//           _isPendingMode = false;
//           _isRetrying = false;
//         });
//
//         String msg = sendToAdminQueue
//             ? "Sent to Admin for Approval (Network Delay)"
//             : "Checked Out Successfully!";
//
//         _showSuccess(msg);
//         if (mounted) Navigator.pop(context);
//       } else {
//         _retryTimer?.cancel();
//         final responseData = jsonDecode(response.body);
//         _showError(responseData['message'] ?? "Check-out failed");
//       }
//     } catch (e) {
//       if (!isRetry) {
//         _startOneMinuteTimer();
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   void _startOneMinuteTimer() {
//     _savePending(needsAdminApproval: false);
//
//     setState(() {
//       _isRetrying = true;
//       _retrySeconds = 0;
//     });
//
//     _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) return;
//
//       setState(() {
//         _retrySeconds++;
//       });
//
//       if (_retrySeconds % 5 == 0) {
//         _checkConnectivityAndSync();
//       }
//
//       if (_retrySeconds >= 60) {
//         timer.cancel();
//         setState(() => _isRetrying = false);
//         _savePending(needsAdminApproval: true);
//
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text("Network timeout. Request saved for Admin Approval."),
//           backgroundColor: Colors.orange,
//           duration: Duration(seconds: 4),
//         ));
//       }
//     });
//   }
//
//   Future<void> _savePending({required bool needsAdminApproval}) async {
//     if (selfieImage == null) return;
//
//     // ✅ FIX: Move file from Cache to Permanent Storage
//     final directory = await getApplicationDocumentsDirectory();
//     final String fileName =
//         'checkout_${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final String newPath = path.join(directory.path, fileName);
//
//     final File newImage = await selfieImage!.copy(newPath);
//
//     final prefs = await SharedPreferences.getInstance();
//     final data = {
//       "imagePath": newImage.path, // ✅ Save the PERMANENT path
//       "lat": _currentPosition!.latitude,
//       "lng": _currentPosition!.longitude,
//       "dateTime": DateTime.now().toIso8601String(),
//       "displayTime": dateTime,
//       "location": location,
//       "coordsText": coordsText,
//       "userName": _userName,
//       "needsAdminApproval": needsAdminApproval,
//     };
//
//     await prefs.setString('pending_checkout', jsonEncode(data));
//
//     setState(() {
//       _isPendingMode = true;
//       selfieImage = newImage;
//     });
//
//     if (!needsAdminApproval && _retrySeconds == 0) {
//       _showError("No Internet. Retrying for 1 minute...");
//     }
//   }
//
//   void _showError(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showSuccess(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.green),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool hasImage = selfieImage != null;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: themeBlue,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: const Text(
//           "Selfie Punch Out",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.access_time, size: 20, color: Colors.black),
//                 const SizedBox(width: 8),
//                 Text(dateTime, style: const TextStyle(fontSize: 16)),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 const Icon(Icons.person_outline, size: 20),
//                 const SizedBox(width: 8),
//                 Text(_userName, style: const TextStyle(fontSize: 16)),
//               ],
//             ),
//
//             const Spacer(),
//
//             if (hasImage)
//               Center(
//                 child: ClipOval(
//                   child: Image.file(
//                     selfieImage!,
//                     height: 160,
//                     width: 160,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//
//             // 🔹 Show Retry Progress
//             if (_isRetrying) ...[
//               const SizedBox(height: 20),
//               Text("Retrying connection... (${60 - _retrySeconds}s left)",
//                   style: const TextStyle(
//                       color: Colors.orange, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 5),
//               LinearProgressIndicator(
//                   value: _retrySeconds / 60, color: Colors.orange),
//             ],
//
//             const SizedBox(height: 20),
//
//             Row(
//               children: [
//                 const Icon(Icons.gps_fixed, size: 18),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     coordsText,
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//
//             Row(
//               children: [
//                 const Icon(Icons.location_on_outlined, size: 18),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     location,
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 20),
//
//             SizedBox(
//               width: double.infinity,
//               height: 52,
//               child: ElevatedButton.icon(
//                 onPressed: _isLoading || _isRetrying
//                     ? null
//                     : (_isPendingMode
//                         ? _attemptSync
//                         : (hasImage ? confirmCheckout : openCamera)),
//                 icon: _isLoading
//                     ? Container()
//                     : Icon(
//                         _isPendingMode
//                             ? Icons.hourglass_bottom
//                             : (hasImage ? Icons.check : Icons.camera_alt),
//                         size: 22,
//                       ),
//                 label: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Text(
//                         _isPendingMode
//                             ? "Pending (Tap to Sync)"
//                             : (hasImage ? "Confirm Clock-Out" : "Take Photo"),
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor:
//                       _isPendingMode ? Colors.orange.shade700 : themeBlue,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
=======
}
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
