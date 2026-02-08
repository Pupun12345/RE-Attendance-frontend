// lib/screens/management/management_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // For location
import 'dart:async'; // For timer
import 'dart:convert'; // For jsonDecode
import 'package:shared_preferences/shared_preferences.dart';

// ✅ --- FIXED IMPORTS ---
import 'package:smartcare_app/screens/shared/login_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkin_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkout_screen.dart';
import 'package:smartcare_app/screens/shared/submit_complaint_screen.dart';
import 'package:smartcare_app/screens/shared/overtime_submission_screen.dart';
import 'package:smartcare_app/screens/shared/holiday_calendar_screen.dart';
import 'package:smartcare_app/screens/management/attendance_overview_screen.dart';
// ✅ --- END OF FIX ---

class ManagementDashboardScreen extends StatefulWidget {
  const ManagementDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ManagementDashboardScreen> createState() =>
      _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends State<ManagementDashboardScreen> {
  int _selectedIndex = 0;
  final Color themeBlue = const Color(0xFF0A3C7B);

  // --- State variables for user data ---
  String _userName = "User Name";
  String _userRole = "Role";
  String _userId = "ID-000";
  String _userEmail = "email@example.com";
  String _userPhone = "1234567890";
  String? _profileImageUrl;
  bool _isLoadingProfile = true;
  String _location = "Fetching location...";
  String _currentStatus = "Checked In (09:00 AM)";
  // ---

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _startStatusTimer();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      final userData = jsonDecode(userString) as Map<String, dynamic>;
      setState(() {
        _userName = userData['name'] ?? 'User Name';
        _userRole = userData['role'] ?? 'Role';
        _userId = userData['userId'] ?? 'ID-000';
        _userEmail = userData['email'] ?? 'email@example.com';
        _userPhone = userData['phone'] ?? '1234567890';
        _profileImageUrl = userData['profileImageUrl'];
      });
    }


    _screens = [
      _buildHomeScreen(),
      const AttendanceOverviewScreen(),
      const SubmitComplaintScreen(),
      _buildProfileScreen(),
    ];

    setState(() {
      _isLoadingProfile = false;
    });
  }

  // --- (Copy/Paste _fetchLocation and _startStatusTimer from Supervisor Dashboard) ---
  void _startStatusTimer() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentStatus = DateTime.now().minute % 2 == 0
            ? "Checked In (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})"
            : "Checked Out (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})";
      });
    });
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = "GPS not enabled";
      });
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = "Location permission denied";
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = "Location permission permanently denied";
      });
      return;
    }
    final Position position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _location =
          "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
    });
  }
  // ---

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Titles for the AppBar
    final List<String> _titles = [
      "Management Dashboard",
      "Attendance Overview",
      "Submit Complaint",
      "My Profile" // Changed from "Settings"
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeBlue,
        title: Text(
          _titles[_selectedIndex], // Use dynamic title
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: themeBlue,
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint), label: "Attendance"),
          BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_rounded), label: "Complaint"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"), // Changed from Settings
        ],
      ),
    );
  }

  // --- Home Screen Widget ---
  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Self-Attendance Card ---
          // buildCard(
          //   title: "Self-Attendance",
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           const Icon(Icons.access_time, size: 18),
          //           const SizedBox(width: 8),
          //           Text(
          //             "Current Status: $_currentStatus",
          //             style: const TextStyle(
          //                 fontSize: 14, fontWeight: FontWeight.w500),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 5),
          //       Row(
          //         children: [
          //           const Icon(Icons.location_on_outlined, size: 18),
          //           const SizedBox(width: 8),
          //           Text(
          //             _location,
          //             style: const TextStyle(
          //                 fontSize: 14, fontWeight: FontWeight.w500),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 15),
          //       Row(
          //         children: [
          //           Expanded(
          //             child: ElevatedButton.icon(
          //               onPressed: () {
          //                 // Navigate to SHARED screen
          //                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SelfieCheckInScreen()));
          //               },
          //               icon: const Icon(Icons.login, color: Colors.white),
          //               label: const Text("Check-In",
          //                   style: TextStyle(color: Colors.white)),
          //               style: ElevatedButton.styleFrom(
          //                 backgroundColor: themeBlue,
          //                 shape: RoundedRectangleBorder(
          //                     borderRadius: BorderRadius.circular(30)),
          //               ),
          //             ),
          //           ),
          //           const SizedBox(width: 12),
          //           Expanded(
          //             child: ElevatedButton.icon(
          //               onPressed: () {
          //                  // Navigate to SHARED screen
          //                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SelfieCheckOutScreen()));
          //               },
          //               icon: const Icon(Icons.logout, color: Colors.white),
          //               label: const Text("Check-Out",
          //                   style: TextStyle(color: Colors.white)),
          //               style: ElevatedButton.styleFrom(
          //                 backgroundColor: themeBlue,
          //                 shape: RoundedRectangleBorder(
          //                     borderRadius: BorderRadius.circular(30)),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
// --- Self-Attendance Card ---
          buildCard(
            title: "Self-Attendance",
            child: Column(
              children: [
                Text(
            "Manage your daily attendance from here",

            style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SelfieCheckInScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text(
                          "Check-In",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SelfieCheckOutScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "Check-Out",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Overtime Card ---
          buildCard(
            title: "Overtime Submission",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Submit your overtime requests for approval."),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       // Navigate to SHARED screen
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const OvertimeSubmissionScreen()));
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text("Submit Overtime", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Holiday Card ---
          buildCard(
            title: "Holiday Calendar",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Check upcoming company holidays."),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       // Navigate to SHARED screen
                       Navigator.push(context, MaterialPageRoute(builder: (context) => HolidayCalendarScreen()));
                    },
                    icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                    label: const Text("View Calendar", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  // --- Profile Screen Widget ---
  Widget _buildProfileScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 70,
            backgroundColor: themeBlue.withOpacity(0.1),
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: (_profileImageUrl == null)
                ? Icon(Icons.person, size: 80, color: themeBlue)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            _userName,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: themeBlue),
          ),
          const SizedBox(height: 8),
          Text(
            _userId,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 20),
          _buildProfileDetailCard(
            icon: Icons.email_outlined,
            label: "Email",
            value: _userEmail,
          ),
          _buildProfileDetailCard(
            icon: Icons.phone_outlined,
            label: "Phone",
            value: _userPhone,
          ),
          _buildProfileDetailCard(
            icon: Icons.badge_outlined,
            label: "Role",
            value: _userRole.substring(0, 1).toUpperCase() + _userRole.substring(1),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Log Out",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper for Profile Cards ---
  Widget _buildProfileDetailCard(
      {required IconData icon, required String label, required String value}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(icon, color: themeBlue, size: 24),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper for Home Cards ---
  Widget buildCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}



// lib/screens/management/management_dashboard_screen.dart
// lib/screens/management/management_dashboard_screen.dart
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'dart:async';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
//
// import 'package:smartcare_app/screens/shared/login_screen.dart';
// import 'package:smartcare_app/screens/shared/selfie_checkin_screen.dart';
// import 'package:smartcare_app/screens/shared/selfie_checkout_screen.dart';
// import 'package:smartcare_app/screens/shared/submit_complaint_screen.dart';
// import 'package:smartcare_app/screens/shared/overtime_submission_screen.dart';
// import 'package:smartcare_app/screens/shared/holiday_calendar_screen.dart';
// import 'package:smartcare_app/screens/management/attendance_overview_screen.dart';
// import 'package:smartcare_app/utils/constants.dart';
//
// class ManagementDashboardScreen extends StatefulWidget {
//   const ManagementDashboardScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ManagementDashboardScreen> createState() =>
//       _ManagementDashboardScreenState();
// }
//
// class _ManagementDashboardScreenState extends State<ManagementDashboardScreen> with WidgetsBindingObserver {
//   int _selectedIndex = 0;
//   final Color themeBlue = const Color(0xFF0A3C7B);
//   final Color accentColor = const Color(0xFF00B4D8);
//   final Color lightBlue = const Color(0xFFE8F4F8);
//
//   String _userName = "User Name";
//   String _userRole = "Role";
//   String _userId = "ID-000";
//   String _userEmail = "email@example.com";
//   String _userPhone = "1234567890";
//   String? _profileImageUrl;
//   bool _isLoadingProfile = true;
//   String _location = "Fetching location...";
//   String _checkInTime = "Not checked in";
//   String _checkOutTime = "Not checked out";
//   bool _isRefreshing = false;
//
//   late final List<Widget> _screens;
//   final GlobalKey<AttendanceOverviewScreenState> _attendanceKey = GlobalKey();
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeData();
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed && _selectedIndex == 0) {
//       // App foreground mein aaya aur home screen active hai
//       _loadTodayAttendanceFromAPI();
//       _fetchLocation();
//     }
//   }
//
//   Future<void> _initializeData() async {
//     await _loadUserData();
//     // User data load hone ke BAAD location aur attendance load karo
//     await Future.wait([
//       _fetchLocation(),
//       _loadTodayAttendanceFromAPI(),
//     ]);
//   }
//
//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userString = prefs.getString('user');
//
//     if (userString != null) {
//       final userData = jsonDecode(userString) as Map<String, dynamic>;
//       if (mounted) {
//         setState(() {
//           _userName = userData['name'] ?? 'User Name';
//           _userRole = userData['role'] ?? 'Role';
//           _userId = userData['userId'] ?? 'ID-000';
//           _userEmail = userData['email'] ?? 'email@example.com';
//           _userPhone = userData['phone'] ?? '1234567890';
//           _profileImageUrl = userData['profileImageUrl'];
//         });
//       }
//     }
//
//     _screens = [
//       _buildHomeScreen(),
//       AttendanceOverviewScreen(key: _attendanceKey),
//       const SubmitComplaintScreen(),
//       _buildProfileScreen(),
//     ];
//
//     if (mounted) {
//       setState(() {
//         _isLoadingProfile = false;
//       });
//     }
//   }
//
//   // Load today's attendance from API
//   Future<void> _loadTodayAttendanceFromAPI() async {
//     print('=== LOADING TODAY ATTENDANCE ===');
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//       final userString = prefs.getString('user');
//
//       if (token == null || userString == null) {
//         print('Token or user not found');
//         return;
//       }
//
//       final Map<String, dynamic> myUser = jsonDecode(userString);
//       final String myUserId = myUser['id'] ?? myUser['_id'];
//       print('My User ID: $myUserId');
//
//       // Get today's date
//       final now = DateTime.now();
//       final String todayDate = DateFormat('yyyy-MM-dd').format(now);
//       print('Today Date: $todayDate');
//
//       final url = Uri.parse(
//           '$apiBaseUrl/api/v1/reports/attendance/daily?startDate=$todayDate&endDate=$todayDate');
//
//       print('API URL: $url');
//
//       final response = await http.get(
//         url,
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       print('Response Status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> allRecords = data['data'];
//         print('Total Records: ${allRecords.length}');
//
//         // Find today's record for current user
//         dynamic todayRecord;
//         for (var record in allRecords) {
//           if (record['user'] is Map) {
//             if (record['user']['_id'] == myUserId || record['user']['id'] == myUserId) {
//               todayRecord = record;
//               break;
//             }
//           } else if (record['user'] is String) {
//             if (record['user'] == myUserId) {
//               todayRecord = record;
//               break;
//             }
//           }
//         }
//
//         if (todayRecord != null) {
//           print('Found today record!');
//           print('CheckIn: ${todayRecord['checkInTime']}');
//           print('CheckOut: ${todayRecord['checkOutTime']}');
//
//           if (mounted) {
//             setState(() {
//               // Parse check-in time
//               if (todayRecord['checkInTime'] != null) {
//                 final checkInDateTime =
//                 DateTime.parse(todayRecord['checkInTime']).toLocal();
//                 _checkInTime = DateFormat('hh:mm a').format(checkInDateTime);
//                 print('Formatted CheckIn: $_checkInTime');
//               } else {
//                 _checkInTime = "Not checked in";
//               }
//
//               // Parse check-out time
//               if (todayRecord['checkOutTime'] != null) {
//                 final checkOutDateTime =
//                 DateTime.parse(todayRecord['checkOutTime']).toLocal();
//                 _checkOutTime = DateFormat('hh:mm a').format(checkOutDateTime);
//                 print('Formatted CheckOut: $_checkOutTime');
//               } else {
//                 _checkOutTime = "Not checked out";
//               }
//             });
//           }
//         } else {
//           print('No record found for today');
//           if (mounted) {
//             setState(() {
//               _checkInTime = "Not checked in";
//               _checkOutTime = "Not checked out";
//             });
//           }
//         }
//       } else {
//         print('API Error: ${response.statusCode}');
//         print('Response Body: ${response.body}');
//         // Fallback to SharedPreferences
//         _loadAttendanceStatusFromPrefs();
//       }
//     } catch (e) {
//       print('Exception loading attendance: $e');
//       // Fallback to SharedPreferences
//       _loadAttendanceStatusFromPrefs();
//     }
//     print('=== END LOADING ATTENDANCE ===');
//   }
//
//   // Fallback method using SharedPreferences
//   Future<void> _loadAttendanceStatusFromPrefs() async {
//     print('Using SharedPreferences fallback');
//     final prefs = await SharedPreferences.getInstance();
//
//     final now = DateTime.now();
//     final todayKey = DateFormat('yyyy-MM-dd').format(now);
//
//     final checkInString = prefs.getString('checkIn_$todayKey');
//     if (checkInString != null) {
//       final checkInDateTime = DateTime.parse(checkInString).toLocal();
//       if (mounted) {
//         setState(() {
//           _checkInTime = DateFormat('hh:mm a').format(checkInDateTime);
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           _checkInTime = "Not checked in";
//         });
//       }
//     }
//
//     final checkOutString = prefs.getString('checkOut_$todayKey');
//     if (checkOutString != null) {
//       final checkOutDateTime = DateTime.parse(checkOutString).toLocal();
//       if (mounted) {
//         setState(() {
//           _checkOutTime = DateFormat('hh:mm a').format(checkOutDateTime);
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           _checkOutTime = "Not checked out";
//         });
//       }
//     }
//   }
//
//   Future<void> _fetchLocation() async {
//     print('=== FETCHING LOCATION ===');
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       print('GPS not enabled');
//       if (mounted) {
//         setState(() {
//           _location = "GPS not enabled";
//         });
//       }
//       return;
//     }
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         print('Location permission denied');
//         if (mounted) {
//           setState(() {
//             _location = "Location permission denied";
//           });
//         }
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       print('Location permission permanently denied');
//       if (mounted) {
//         setState(() {
//           _location = "Location permission permanently denied";
//         });
//       }
//       return;
//     }
//
//     try {
//       final Position position = await Geolocator.getCurrentPosition();
//       print('Position: ${position.latitude}, ${position.longitude}');
//
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//
//       if (placemarks.isNotEmpty && mounted) {
//         final place = placemarks[0];
//         String locationText = '';
//
//         if (place.subLocality != null && place.subLocality!.isNotEmpty) {
//           locationText = place.subLocality!;
//         } else if (place.locality != null && place.locality!.isNotEmpty) {
//           locationText = place.locality!;
//         }
//
//         if (place.locality != null &&
//             place.locality!.isNotEmpty &&
//             place.subLocality != place.locality) {
//           locationText +=
//           locationText.isEmpty ? place.locality! : ', ${place.locality}';
//         }
//
//         if (place.administrativeArea != null &&
//             place.administrativeArea!.isNotEmpty) {
//           locationText += locationText.isEmpty
//               ? place.administrativeArea!
//               : ', ${place.administrativeArea}';
//         }
//
//         print('Location Text: $locationText');
//
//         setState(() {
//           _location = locationText.isNotEmpty
//               ? locationText
//               : "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
//         });
//       }
//     } catch (e) {
//       print('Location Error: $e');
//       if (mounted) {
//         setState(() {
//           _location = "Unable to fetch location";
//         });
//       }
//     }
//     print('=== END FETCHING LOCATION ===');
//   }
//
//   Future<void> _refreshHomeData() async {
//     if (_isRefreshing) return;
//
//     setState(() {
//       _isRefreshing = true;
//     });
//
//     await Future.wait([
//       _fetchLocation(),
//       _loadTodayAttendanceFromAPI(),
//     ]);
//
//     setState(() {
//       _isRefreshing = false;
//     });
//   }
//
//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     if (mounted) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginScreen()),
//             (Route<dynamic> route) => false,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final List<String> _titles = [
//       "Management Dashboard",
//       "Attendance Overview",
//       "Submit Complaint",
//       "My Profile"
//     ];
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         backgroundColor: themeBlue,
//         title: Text(
//           _titles[_selectedIndex],
//           style: const TextStyle(
//             fontWeight: FontWeight.w700,
//             color: Colors.white,
//             fontSize: 20,
//             letterSpacing: 0.5,
//           ),
//         ),
//         elevation: 0,
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//         actions: _selectedIndex == 0
//             ? [
//           IconButton(
//             icon: _isRefreshing
//                 ? const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                 color: Colors.white,
//                 strokeWidth: 2,
//               ),
//             )
//                 : const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _isRefreshing ? null : _refreshHomeData,
//           ),
//         ]
//             : null,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [themeBlue, themeBlue.withOpacity(0.85)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: _isLoadingProfile
//           ? Center(
//         child: CircularProgressIndicator(
//           color: themeBlue,
//           strokeWidth: 3,
//         ),
//       )
//           : IndexedStack(
//         index: _selectedIndex,
//         children: _screens,
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 20,
//               offset: const Offset(0, -4),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildNavItem(0, Icons.home_rounded, "Home"),
//                 _buildNavItem(1, Icons.fingerprint, "Attendance"),
//                 _buildNavItem(2, Icons.report_problem_rounded, "Complaint"),
//                 _buildNavItem(3, Icons.person_rounded, "Profile"),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavItem(int index, IconData icon, String label) {
//     final isSelected = _selectedIndex == index;
//     return GestureDetector(
//       onTap: () {
//         setState(() => _selectedIndex = index);
//         // Refresh attendance screen when switching to it
//         if (index == 1 && _attendanceKey.currentState != null) {
//           _attendanceKey.currentState!.refreshData();
//         }
//         // Refresh home screen when switching back to it
//         if (index == 0) {
//           _loadTodayAttendanceFromAPI();
//           _fetchLocation();
//         }
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: EdgeInsets.symmetric(
//           horizontal: isSelected ? 16 : 12,
//           vertical: 8,
//         ),
//         decoration: BoxDecoration(
//           color: isSelected ? themeBlue.withOpacity(0.1) : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? themeBlue : Colors.grey[600],
//               size: isSelected ? 28 : 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: isSelected ? 12 : 11,
//                 fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
//                 color: isSelected ? themeBlue : Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHomeScreen() {
//     return RefreshIndicator(
//       onRefresh: _refreshHomeData,
//       color: themeBlue,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               lightBlue.withOpacity(0.3),
//               Colors.white,
//             ],
//           ),
//         ),
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Welcome Header
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [themeBlue, themeBlue.withOpacity(0.8)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: themeBlue.withOpacity(0.3),
//                       blurRadius: 20,
//                       offset: const Offset(0, 10),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 32,
//                       backgroundColor: Colors.white.withOpacity(0.2),
//                       backgroundImage: _profileImageUrl != null
//                           ? NetworkImage(_profileImageUrl!)
//                           : null,
//                       child: _profileImageUrl == null
//                           ? const Icon(Icons.person,
//                           size: 32, color: Colors.white)
//                           : null,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Welcome back,",
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             _userName,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.w700,
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             _userId,
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.8),
//                               fontSize: 13,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.verified_user,
//                         color: Colors.white,
//                         size: 24,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//
//               // Self-Attendance Card
//               _buildModernCard(
//                 title: "Self-Attendance",
//                 icon: Icons.access_time_rounded,
//                 gradient: LinearGradient(
//                   colors: [Colors.blue[600]!, Colors.blue[400]!],
//                 ),
//                 child: Column(
//                   children: [
//                     _buildInfoRow(
//                       Icons.login,
//                       "Check-In Time",
//                       _checkInTime,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInfoRow(
//                       Icons.logout,
//                       "Check-Out Time",
//                       _checkOutTime,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInfoRow(
//                       Icons.location_on_outlined,
//                       "Current Location",
//                       _location,
//                     ),
//                     const SizedBox(height: 20),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildActionButton(
//                             label: "Check-In",
//                             icon: Icons.login,
//                             color: Colors.green[600]!,
//                             onPressed: () async {
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                   const SelfieCheckInScreen(),
//                                 ),
//                               );
//                               // Reload attendance after check-in
//                               _loadTodayAttendanceFromAPI();
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildActionButton(
//                             label: "Check-Out",
//                             icon: Icons.logout,
//                             color: Colors.red[600]!,
//                             onPressed: () async {
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                   const SelfieCheckOutScreen(),
//                                 ),
//                               );
//                               // Reload attendance after check-out
//                               _loadTodayAttendanceFromAPI();
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Quick Actions Grid
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildQuickActionCard(
//                       title: "Overtime",
//                       subtitle: "Submit Request",
//                       icon: Icons.access_time_filled,
//                       color: Colors.orange[600]!,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                             const OvertimeSubmissionScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildQuickActionCard(
//                       title: "Holidays",
//                       subtitle: "View Calendar",
//                       icon: Icons.calendar_month_rounded,
//                       color: Colors.purple[600]!,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => HolidayCalendarScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildModernCard({
//     required String title,
//     required IconData icon,
//     required Gradient gradient,
//     required Widget child,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 20,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               gradient: gradient,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(icon, color: Colors.white, size: 24),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: child,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(IconData icon, String label, String value) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: lightBlue,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(icon, size: 20, color: themeBlue),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActionButton({
//     required String label,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onPressed,
//   }) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 20),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuickActionCard({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: color, size: 28),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProfileScreen() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             lightBlue.withOpacity(0.3),
//             Colors.white,
//           ],
//         ),
//       ),
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//             Stack(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [themeBlue, accentColor],
//                     ),
//                   ),
//                   child: CircleAvatar(
//                     radius: 65,
//                     backgroundColor: Colors.white,
//                     child: CircleAvatar(
//                       radius: 60,
//                       backgroundColor: lightBlue,
//                       backgroundImage: _profileImageUrl != null
//                           ? NetworkImage(_profileImageUrl!)
//                           : null,
//                       child: _profileImageUrl == null
//                           ? Icon(Icons.person, size: 60, color: themeBlue)
//                           : null,
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 5,
//                   right: 5,
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.green[500],
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 3),
//                     ),
//                     child: const Icon(
//                       Icons.verified,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _userName,
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.w800,
//                 color: themeBlue,
//                 letterSpacing: 0.5,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//               decoration: BoxDecoration(
//                 color: lightBlue,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 _userId,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: themeBlue,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             _buildProfileCard(
//               icon: Icons.email_rounded,
//               label: "Email Address",
//               value: _userEmail,
//               color: Colors.blue[600]!,
//             ),
//             _buildProfileCard(
//               icon: Icons.phone_rounded,
//               label: "Phone Number",
//               value: _userPhone,
//               color: Colors.green[600]!,
//             ),
//             _buildProfileCard(
//               icon: Icons.badge_rounded,
//               label: "Role",
//               value: _userRole.substring(0, 1).toUpperCase() +
//                   _userRole.substring(1),
//               color: Colors.purple[600]!,
//             ),
//             const SizedBox(height: 30),
//             Container(
//               width: double.infinity,
//               height: 56,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.red[600]!, Colors.red[500]!],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.red.withOpacity(0.3),
//                     blurRadius: 12,
//                     offset: const Offset(0, 6),
//                   ),
//                 ],
//               ),
//               child: ElevatedButton(
//                 onPressed: _logout,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.transparent,
//                   shadowColor: Colors.transparent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.logout_rounded, color: Colors.white, size: 22),
//                     SizedBox(width: 10),
//                     Text(
//                       "Log Out",
//                       style: TextStyle(
//                         fontSize: 17,
//                         color: Colors.white,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProfileCard({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color color,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: color, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
//         ],
//       ),
//     );
//   }
// }