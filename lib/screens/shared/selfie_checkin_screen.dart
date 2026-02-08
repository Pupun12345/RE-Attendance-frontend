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
  String _fullAddress = ""; // ✅ Complete address for API
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
        _fullAddress = jsonData['fullAddress'] ?? ""; // ✅ Restore full address
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

    await _uploadData(
        img,
        pendingData['lat'],
        pendingData['lng'],
        pendingData['fullAddress'] ?? "", // ✅ Pass full address
        pendingData['dateTime'],
        true,
        needsAdmin
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
    if (!serviceEnabled) {
      setState(() {
        location = "Location services disabled";
        coordsText = "Enable GPS";
      });
      return;
    }

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      setState(() {
        location = "Location permission denied";
        coordsText = "Allow location access";
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high); // ✅ Changed to high accuracy
      _currentPosition = pos;

      setState(() {
        coordsText =
        "Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}";
      });

      // ✅ Get detailed address
      List<Placemark> places =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (places.isNotEmpty) {
        Placemark place = places.first;

        // ✅ Build complete address
        List<String> addressParts = [];

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        String fullAddr = addressParts.join(", ");
        String displayAddr = "${place.locality ?? "Unknown"}, ${place.subLocality ?? ""}";

        setState(() {
          _fullAddress = fullAddr.isNotEmpty ? fullAddr : "Address unavailable";
          location = displayAddr.isNotEmpty ? displayAddr : "Location found";
        });
      }
    } catch (e) {
      setState(() {
        location = "Failed to fetch location";
        coordsText = "Error: ${e.toString()}";
      });
    }
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

  Future<void> _uploadData(
      File img,
      double lat,
      double lng,
      String address, // ✅ Accept address parameter
      String dt,
      bool isRetry,
      bool sendToAdminQueue
      ) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final role = prefs.getString("role");
      String endpoint = sendToAdminQueue
          ? "$_apiUrl/api/v1/attendance/checkin-pending"
          : "$_apiUrl/api/v1/attendance/checkin";

      // ✅ Print Request Start Time
      final requestStartTime = DateTime.now();
      print("\n╔════════════════════════════════════════════╗");
      print("║       API REQUEST START                    ║");
      print("╚════════════════════════════════════════════╝");
      print("⏰ Request Time: ${_formatDateTime(requestStartTime)}");
      print("🔗 Endpoint: $endpoint");
      print("📍 Location: $address");
      print("📌 Coordinates: ($lat, $lng)");
      print("📅 DateTime: ${isRetry ? dt : DateTime.now().toIso8601String()}");
      print("🔄 Is Retry: $isRetry");
      print("⚠️  Admin Queue: $sendToAdminQueue");
      print("🖼️  Image Path: ${img.path}");
      print("═══════════════════════════════════════════════\n");

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers["Authorization"] = "Bearer $token";

      // ✅ Send proper location format
      request.fields["location"] = address.isNotEmpty ? address : "$lat,$lng";
      request.fields["latitude"] = lat.toString();
      request.fields["longitude"] = lng.toString();
      request.fields["dateTime"] =
      isRetry ? dt : DateTime.now().toIso8601String();

      request.files.add(await http.MultipartFile.fromPath(
        'attendanceImage',
        img.path,
        contentType: MediaType("image", "jpeg"),
      ));

      print("📤 Sending request...\n");
      var resp = await request.send();
      var res = await http.Response.fromStream(resp);

      final requestEndTime = DateTime.now();
      final duration = requestEndTime.difference(requestStartTime);

      // ✅ Print Response Details
      print("\n╔════════════════════════════════════════════╗");
      print("║       API RESPONSE RECEIVED                ║");
      print("╚════════════════════════════════════════════╝");
      print("⏰ Response Time: ${_formatDateTime(requestEndTime)}");
      print("⏱️  Duration: ${duration.inMilliseconds}ms");
      print("📊 Status Code: ${res.statusCode}");
      print("📦 Response Body: ${res.body}");
      print("═══════════════════════════════════════════════\n");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("✅ SUCCESS: Check-in completed successfully!\n");

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
        print("❌ ERROR: Request failed with status ${res.statusCode}\n");

        _retryTimer?.cancel();
        final responseData = jsonDecode(res.body);
        _showError(responseData['message'] ?? "Check-in failed");
      }
    } catch (e) {
      print("\n╔════════════════════════════════════════════╗");
      print("║       API REQUEST FAILED                   ║");
      print("╚════════════════════════════════════════════╝");
      print("❌ Error: $e");
      print("═══════════════════════════════════════════════\n");

      if (!isRetry) {
        _startOneMinuteTimer();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${_formatTime(dt)}";
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
    if (selfieImage == null) {
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
      return;
    }

    await _uploadData(
        selfieImage!,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _fullAddress, // ✅ Send full address
        "",
        false,
        false
    );
  }

  Future<void> _savePending({required bool needsAdminApproval}) async {
    if (selfieImage == null) return;

    // ✅ Move file from Cache to Permanent Storage
    final directory = await getApplicationDocumentsDirectory();
    final String fileName =
        'checkin_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = path.join(directory.path, fileName);

    // Copy the file
    final File newImage = await selfieImage!.copy(newPath);

    final prefs = await SharedPreferences.getInstance();
    final data = {
      "imagePath": newImage.path,
      "lat": _currentPosition!.latitude,
      "lng": _currentPosition!.longitude,
      "fullAddress": _fullAddress, // ✅ Save full address
      "dateTime": DateTime.now().toIso8601String(),
      "displayTime": dateTime,
      "location": location,
      "needsAdminApproval": needsAdminApproval,
    };

    await prefs.setString("pending_checkin", jsonEncode(data));

    setState(() {
      _isPendingMode = true;
      selfieImage = newImage;
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: themeBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(ctx),
        ),
        title: const Text(
          "Selfie Check-In",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
                                const Icon(Icons.sync, color: Colors.orange, size: 20),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
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
                    _buildInfoRow(Icons.location_on_outlined, "Location", location),
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
                      : (hasImage ? confirmCheckIn : openCamera)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isLoading || _isRetrying ? 0 : 4,
                    shadowColor: themeBlue.withOpacity(0.4),
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
                            : (hasImage ? Icons.check_circle : Icons.camera_alt),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isPendingMode
                            ? "Retry Sync"
                            : (hasImage ? "Confirm Check-In" : "Take Selfie"),
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
        ),
      ),
    );
  }

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







// // lib/screens/shared/selfie_checkin_screen.dart
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
// class SelfieCheckInScreen extends StatefulWidget {
//   const SelfieCheckInScreen({super.key});
//
//   @override
//   State<SelfieCheckInScreen> createState() => _SelfieCheckInScreenState();
// }
//
// class _SelfieCheckInScreenState extends State<SelfieCheckInScreen> {
//   String dateTime = "";
//   String location = "Fetching location...";
//   String coordsText = "Fetching coordinates...";
//   final Color themeBlue = const Color(0xFF0B3B8C);
//   File? selfieImage;
//   Position? _currentPosition;
//   bool _isLoading = false;
//   String _userName = "Unknown";
//
//   bool _isPendingMode = false;
//   bool _isRetrying = false;
//   int _retrySeconds = 0;
//   Timer? _retryTimer;
//
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
//     Connectivity()
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
//     setState(() => _userName = prefs.getString('userName') ?? "Unknown");
//   }
//
//   Future<void> _checkPendingData() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? pending = prefs.getString("pending_checkin");
//     if (pending != null) {
//       final jsonData = jsonDecode(pending);
//       bool needsAdmin = jsonData['needsAdminApproval'] ?? false;
//
//       setState(() {
//         _isPendingMode = true;
//         selfieImage = File(jsonData['imagePath']);
//         coordsText = "Lat: ${jsonData['lat']}, Lng: ${jsonData['lng']}";
//         location = jsonData['location'];
//         dateTime = jsonData['displayTime'] ?? "Pending Time";
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
//     String? pending = prefs.getString("pending_checkin");
//     if (pending == null) return;
//
//     final pendingData = jsonDecode(pending);
//     File img = File(pendingData['imagePath']);
//     bool needsAdmin = pendingData['needsAdminApproval'] ?? false;
//
//     await _uploadData(img, pendingData['lat'], pendingData['lng'],
//         pendingData['dateTime'], true, needsAdmin);
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
//         dateTime =
//             "${now.day.toString().padLeft(2, '0')} ${_month(now.month)} ${now.year} ${_formatTime(now)}";
//       });
//     });
//   }
//
//   String _month(int m) => [
//         "Jan",
//         "Feb",
//         "Mar",
//         "Apr",
//         "May",
//         "Jun",
//         "Jul",
//         "Aug",
//         "Sep",
//         "Oct",
//         "Nov",
//         "Dec"
//       ][m - 1];
//
//   String _formatTime(DateTime now) {
//     int hour = now.hour;
//     String ampm = hour >= 12 ? "PM" : "AM";
//     hour = hour % 12 == 0 ? 12 : hour % 12;
//     return "$hour:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} $ampm";
//   }
//
//   Future<void> fetchLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;
//
//     LocationPermission p = await Geolocator.checkPermission();
//     if (p == LocationPermission.denied) {
//       p = await Geolocator.requestPermission();
//     }
//     if (p == LocationPermission.deniedForever) return;
//
//     try {
//       final pos = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.best);
//       _currentPosition = pos;
//       setState(() {
//         coordsText =
//             "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
//       });
//
//       List<Placemark> places =
//           await placemarkFromCoordinates(pos.latitude, pos.longitude);
//       Placemark place = places.first;
//       setState(() {
//         location = "${place.locality ?? ""}, ${place.subLocality ?? ""}";
//       });
//     } catch (e) {}
//   }
//
//   Future<bool> _checkInternet() async {
//     var results = await Connectivity().checkConnectivity();
//     return results.any((r) => r != ConnectivityResult.none);
//   }
//
//   Future<void> openCamera() async {
//     final picked = await ImagePicker().pickImage(
//       source: ImageSource.camera,
//       preferredCameraDevice: CameraDevice.front,
//       imageQuality: 85,
//     );
//
//     if (picked != null) {
//       setState(() => selfieImage = File(picked.path));
//     }
//   }
//
//   Future<void> _uploadData(File img, double lat, double lng, String dt,
//       bool isRetry, bool sendToAdminQueue) async {
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("token");
//       final role = prefs.getString("role");
//       String endpoint = sendToAdminQueue
//           ? "$_apiUrl/api/v1/attendance/checkin-pending"
//           : "$_apiUrl/api/v1/attendance/checkin";
//
//       var request = http.MultipartRequest('POST', Uri.parse(endpoint));
//       request.headers["Authorization"] = "Bearer $token";
//
//       request.fields["location"] = "$lat,$lng";
//       request.fields["dateTime"] =
//           isRetry ? dt : DateTime.now().toIso8601String();
//
//       request.files.add(await http.MultipartFile.fromPath(
//         'attendanceImage',
//         img.path,
//         contentType: MediaType("image", "jpeg"),
//       ));
//
//       var resp = await request.send();
//       var res = await http.Response.fromStream(resp);
//
//       if (res.statusCode == 200 || res.statusCode == 201) {
//         _retryTimer?.cancel();
//         await prefs.remove("pending_checkin");
//
//         setState(() {
//           _isPendingMode = false;
//           _isRetrying = false;
//         });
//
//         String msg = sendToAdminQueue
//             ? "Sent to Admin for Approval (Network Delay)"
//             : "Checked In Successfully!";
//
//         _showSuccess(msg);
//         if (mounted) Navigator.pop(context);
//       } else {
//         _retryTimer?.cancel();
//         final responseData = jsonDecode(res.body);
//         _showError(responseData['message'] ?? "Check-in failed");
//       }
//     } catch (e) {
//       if (!isRetry) {
//         _startOneMinuteTimer();
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
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
//   Future<void> confirmCheckIn() async {
//     if (selfieImage == null) return;
//     if (_currentPosition == null) return;
//
//     await _uploadData(selfieImage!, _currentPosition!.latitude,
//         _currentPosition!.longitude, "", false, false);
//   }
//
//   Future<void> _savePending({required bool needsAdminApproval}) async {
//     if (selfieImage == null) return;
//
//     // ✅ FIX: Move file from Cache to Permanent Storage
//     final directory = await getApplicationDocumentsDirectory();
//     final String fileName =
//         'checkin_${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final String newPath = path.join(directory.path, fileName);
//
//     // Copy the file
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
//       "needsAdminApproval": needsAdminApproval,
//     };
//
//     await prefs.setString("pending_checkin", jsonEncode(data));
//
//     setState(() {
//       _isPendingMode = true;
//       selfieImage = newImage; // Update UI to refer to the safe file
//     });
//
//     if (!needsAdminApproval && _retrySeconds == 0) {
//       _showError("No Internet. Retrying for 1 minute...");
//     }
//   }
//
//   void _showError(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg),
//       backgroundColor: Colors.red,
//     ));
//   }
//
//   void _showSuccess(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg),
//       backgroundColor: Colors.green,
//     ));
//   }
//
//   @override
//   Widget build(BuildContext ctx) {
//     bool hasImage = selfieImage != null;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: themeBlue,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(ctx),
//         ),
//         title:
//             const Text("Selfie Punch", style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         child: Column(
//           children: [
//             Row(children: [
//               const Icon(Icons.access_time),
//               const SizedBox(width: 8),
//               Text(dateTime)
//             ]),
//             Row(children: [
//               const Icon(Icons.person_outline),
//               const SizedBox(width: 8),
//               Text(_userName)
//             ]),
//             const Spacer(),
//             if (hasImage)
//               ClipOval(
//                   child: Image.file(selfieImage!,
//                       height: 160, width: 160, fit: BoxFit.cover)),
//             if (_isRetrying) ...[
//               const SizedBox(height: 20),
//               Text("Retrying connection... (${60 - _retrySeconds}s left)",
//                   style: const TextStyle(
//                       color: Colors.orange, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 5),
//               LinearProgressIndicator(
//                   value: _retrySeconds / 60, color: Colors.orange),
//             ],
//             const SizedBox(height: 20),
//             Row(children: [
//               const Icon(Icons.gps_fixed),
//               const SizedBox(width: 8),
//               Expanded(child: Text(coordsText))
//             ]),
//             Row(children: [
//               const Icon(Icons.location_on_outlined),
//               const SizedBox(width: 8),
//               Expanded(child: Text(location))
//             ]),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading || _isRetrying
//                     ? null
//                     : (_isPendingMode
//                         ? _attemptSync
//                         : (hasImage ? confirmCheckIn : openCamera)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: themeBlue,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(50)),
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Text(
//                         _isPendingMode
//                             ? "Pending (Tap to Sync)"
//                             : (hasImage ? "Confirm Check-In" : "Take Photo"),
//                         style: const TextStyle(
//                             fontWeight: FontWeight.bold, color: Colors.white),
//                       ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
