// lib/screens/supervisor/supervisor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ --- FIXED IMPORTS ---
import 'package:smartcare_app/screens/shared/login_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkin_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkout_screen.dart';
import 'package:smartcare_app/screens/shared/overtime_submission_screen.dart';
import 'package:smartcare_app/screens/shared/holiday_calendar_screen.dart';
import 'package:smartcare_app/screens/shared/submit_complaint_screen.dart';
import 'package:smartcare_app/screens/supervisor/attendance_detail_screen.dart';
import 'package:smartcare_app/screens/supervisor/workers_screen.dart';
// ✅ --- END OF FIX ---

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  String _currentStatus = "Checked In (09:00 AM)";
  String _location = "Fetching location...";
  int _selectedIndex = 0;

  String _userName = "User Name";
  String _userRole = "Role";
  String _userId = "ID-000";
  String _userEmail = "email@example.com";
  String _userPhone = "1234567890";
  String? _profileImageUrl;
  bool _isLoadingProfile = true;
  bool _allowCamera = false;
  bool _allowLocation = false;
  bool _allowContact = false;


  final Color themeBlue = const Color(0xFF0B3B8C);
  final TextEditingController _searchController = TextEditingController();

  late final List<Widget> _screens;

  void _showUserAccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStatePopup) {
            final bool canContinue =
                _allowCamera || _allowLocation || _allowContact;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "User Data Access",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "To enable field tracking, please allow camera and location access during check-in and check-out.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),


                    // ✅ Camera checkbox
                    CheckboxListTile(
                      value: _allowCamera,
                      onChanged: (val) {
                        setStatePopup(() {
                          _allowCamera = val ?? false;
                        });
                      },
                      title: const Text("Allow Camera"),
                      secondary: const Icon(Icons.camera_alt),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // ✅ Location checkbox
                    CheckboxListTile(
                      value: _allowLocation,
                      onChanged: (val) {
                        setStatePopup(() {
                          _allowLocation = val ?? false;
                        });
                      },
                      title: const Text("Allow Location"),
                      secondary: const Icon(Icons.location_on),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // ✅ Contact checkbox (NEW)
                    CheckboxListTile(
                      value: _allowContact,
                      onChanged: (val) {
                        setStatePopup(() {
                          _allowContact = val ?? false;
                        });
                      },
                      title: const Text("Allow Contacts"),
                      secondary: const Icon(Icons.contacts),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: canContinue
                            ? () => Navigator.pop(context)
                            : null, // ❌ disabled until choose
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          "Allow",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _startStatusTimer();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUserAccessPopup();
    });
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
      _buildHomeScreen(), // Index 0
      const AttendanceDetailScreen(), // Index 1
      const SubmitComplaintScreen(), // Index 2
      const WorkersScreen(), // Index 3
      _buildProfileScreen(), // Index 4
    ];

    setState(() {
      _isLoadingProfile = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

  Widget buildCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of titles for the AppBar
    final List<String> _titles = [
      "Supervisor Dashboard",
      "Attendance Detail",
      "Submit Complaint",
      "Workers List",
      "My Profile"
    ];

    // Hide parent AppBar when child screens provide their own header (indices 1,2,3)
    final bool hideParentAppBar = _selectedIndex == 1 || _selectedIndex == 2 || _selectedIndex == 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),

      appBar: hideParentAppBar
          ? null
          : AppBar(
        title: Text(
          _titles[_selectedIndex], // Dynamic title
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: themeBlue,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false, // Removes back arrow
      ),

      // Body now uses an IndexedStack to keep state
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator()) // Show loader while screens init
          : IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        selectedItemColor: themeBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: "Attendance"),
          BottomNavigationBarItem(icon: Icon(Icons.report_gmailerrorred_outlined), label: "Complaint"),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: "Workers"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSelfAttendanceCard(),
          buildWorkerSearchCard(),
          buildOvertimeCard(),
          buildHolidayCard(),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // --- Profile Picture ---
          CircleAvatar(
            radius: 70,
            backgroundColor: themeBlue.withOpacity(0.1),
            // Use NetworkImage if URL exists, else show icon
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: (_profileImageUrl == null)
                ? Icon(Icons.person, size: 80, color: themeBlue)
                : null,
          ),
          const SizedBox(height: 20),
          // --- User Name ---
          Text(
            _userName, // Use state variable
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: themeBlue),
          ),
          const SizedBox(height: 8),
          // --- User ID ---
          Text(
            _userId, // Use state variable
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 20),

          // --- User details cards ---
          _buildProfileDetailCard(
            icon: Icons.email_outlined,
            label: "Email",
            value: _userEmail, // Use state variable
          ),
          _buildProfileDetailCard(
            icon: Icons.phone_outlined,
            label: "Phone",
            value: _userPhone, // Use state variable
          ),
          _buildProfileDetailCard(
            icon: Icons.badge_outlined,
            label: "Role",
            value: _userRole.substring(0, 1).toUpperCase() + _userRole.substring(1), // Capitalize role
          ),
          const SizedBox(height: 40),

          // --- Logout Button ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout, // Call the logout function
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

  Widget buildSelfAttendanceCard() {
    return buildCard(
      title: "Self-Attendance",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          Text(
      "Manage your daily attendance from here",

      style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
=======
          Row(
            children: [
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text("Current Status: $_currentStatus")),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(_location)),
            ],
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SelfieCheckInScreen()));
                  },
                  icon: const Icon(Icons.login_outlined),
                  label: const Text("Check-In"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const SelfieCheckOutScreen()));
                  },
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text("Check-Out"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildWorkerSearchCard() {
    return buildCard(
      title: "Worker Attendance Search",
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Enter worker ID or name",
              prefixIcon: const Icon(Icons.person_outline),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkersScreen(
                      initialSearchQuery: _searchController.text,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text("Search"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOvertimeCard() {
    return buildCard(
      title: "Overtime Submission",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Submit your overtime requests quickly and easily."),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                        const OvertimeSubmissionScreen()));
              },
              icon: const Icon(Icons.send),
              label: const Text("Overtime Submit"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHolidayCard() {
    return buildCard(
      title: "Holiday Calendar",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Check upcoming holidays assigned by Admin."),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HolidayCalendarScreen()));
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text("View Holiday"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}