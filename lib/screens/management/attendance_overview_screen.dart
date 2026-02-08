// lib/screens/management/attendance_overview_screen.dart
import 'dart:convert';
<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:smartcare_app/utils/constants.dart';

// 1. Model for attendance data
=======
import 'package:flutter/material.dart'; // ✅ --- THIS WAS THE BROKEN LINE ---
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

// 1. A Model to hold the fetched attendance data
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
class AttendanceRecord {
  final String id;
  final String status;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  AttendanceRecord({
    required this.id,
    required this.status,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
<<<<<<< HEAD
      id: json['_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      date: DateTime.parse(json['date']).toLocal(),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime']).toLocal()
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime']).toLocal()
=======
      id: json['_id'],
      status: json['status'],
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
          : null,
    );
  }
}

<<<<<<< HEAD
=======
// 2. Convert to StatefulWidget to fetch data
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
class AttendanceOverviewScreen extends StatefulWidget {
  const AttendanceOverviewScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceOverviewScreen> createState() =>
<<<<<<< HEAD
      AttendanceOverviewScreenState();
}

class AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  final Color themeBlue = const Color(0xFF0A3C7B);
  final Color lightBlue = const Color(0xFFE8F4F8);

=======
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  final Color themeBlue = const Color(0xFF0A3C7B);
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
  List<AttendanceRecord> _myAttendanceRecords = [];
  bool _isLoading = true;
  String? _error;

<<<<<<< HEAD
  // Today's attendance data
  String _currentLocation = "Fetching location...";
  String _todayCheckIn = "Not checked in";
  String _todayCheckOut = "Not checked out";
  bool _isLocationLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchCurrentLocation(),
      _fetchMyAttendance(),
      _loadTodayAttendance(),
    ]);
  }

  // PUBLIC METHOD - Can be called from parent widget
  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
      _isLocationLoading = true;
      _error = null;
    });
    await _initializeData();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = "GPS not enabled";
          _isLocationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = "Location permission denied";
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = "Location permission denied";
          _isLocationLoading = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition();

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        String locationText = '';

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          locationText = place.subLocality!;
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          locationText = place.locality!;
        }

        if (place.locality != null &&
            place.locality!.isNotEmpty &&
            place.subLocality != place.locality) {
          locationText +=
          locationText.isEmpty ? place.locality! : ', ${place.locality}';
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          locationText += locationText.isEmpty
              ? place.administrativeArea!
              : ', ${place.administrativeArea}';
        }

        setState(() {
          _currentLocation = locationText.isNotEmpty
              ? locationText
              : "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = "Unable to fetch location";
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userString = prefs.getString('user');

      if (token == null || userString == null) {
        return;
      }

      final Map<String, dynamic> myUser = jsonDecode(userString);
      final String myUserId = myUser['id'] ?? myUser['_id'];

      // Get today's date
      final now = DateTime.now();
      final String todayDate = DateFormat('yyyy-MM-dd').format(now);

      final url = Uri.parse(
          '$apiBaseUrl/api/v1/reports/attendance/daily?startDate=$todayDate&endDate=$todayDate');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allRecords = data['data'];

        // Find today's record
        final todayRecord = allRecords.firstWhere(
              (record) {
            if (record['user'] is Map) {
              return (record['user']['_id'] == myUserId ||
                  record['user']['id'] == myUserId);
            } else if (record['user'] is String) {
              return record['user'] == myUserId;
            }
            return false;
          },
          orElse: () => null,
        );

        if (todayRecord != null && mounted) {
          if (todayRecord['checkInTime'] != null) {
            final checkInDateTime =
            DateTime.parse(todayRecord['checkInTime']).toLocal();
            setState(() {
              _todayCheckIn = DateFormat('hh:mm a').format(checkInDateTime);
            });
          } else {
            setState(() {
              _todayCheckIn = "Not checked in";
            });
          }

          if (todayRecord['checkOutTime'] != null) {
            final checkOutDateTime =
            DateTime.parse(todayRecord['checkOutTime']).toLocal();
            setState(() {
              _todayCheckOut = DateFormat('hh:mm a').format(checkOutDateTime);
            });
          } else {
            setState(() {
              _todayCheckOut = "Not checked out";
            });
          }
        } else {
          setState(() {
            _todayCheckIn = "Not checked in";
            _todayCheckOut = "Not checked out";
          });
        }
      }
    } catch (e) {
      print('Error loading today attendance: $e');
    }
  }
=======
  @override
  void initState() {
    super.initState();
    _fetchMyAttendance();
  }

  // lib/screens/management/attendance_overview_screen.dart

  // ... (keep your imports and AttendanceRecord class as they are) ...
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3

  Future<void> _fetchMyAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userString = prefs.getString('user');

      if (token == null || userString == null) {
        throw Exception("Not authorized.");
      }

      final Map<String, dynamic> myUser = jsonDecode(userString);
<<<<<<< HEAD
      final String myUserId = myUser['id'] ?? myUser['_id'];

      // Last 7 days INCLUDING today
      final now = DateTime.now();
      final String endDate = DateFormat('yyyy-MM-dd').format(now);
      final String startDate =
      DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 6)));
=======
      final String myUserId = myUser['id'] ?? myUser['_id']; // Handle both ID formats

      // Use a robust date range (e.g., past 90 days)
      final String endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String startDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 90)));
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3

      final url = Uri.parse(
          '$apiBaseUrl/api/v1/reports/attendance/daily?startDate=$startDate&endDate=$endDate');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allRecords = data['data'];

<<<<<<< HEAD
        // Filter only my records
        final List<AttendanceRecord> myRecords = allRecords
            .where((record) {
          if (record['user'] is Map) {
            return record['user']['_id'] == myUserId ||
                record['user']['id'] == myUserId;
          } else if (record['user'] is String) {
            return record['user'] == myUserId;
          }
          return false;
        })
=======
        // ✅ BETTER FILTERING LOGIC
        final List<AttendanceRecord> myRecords = allRecords
            .where((record) {
              // Check if 'user' is an object or just an ID string
              if (record['user'] is Map) {
                return record['user']['_id'] == myUserId || record['user']['id'] == myUserId;
              } else if (record['user'] is String) {
                return record['user'] == myUserId;
              }
              return false;
            })
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
            .map((record) => AttendanceRecord.fromJson(record))
            .toList();

        // Sort by date (newest first)
        myRecords.sort((a, b) => b.date.compareTo(a.date));

        if (mounted) {
          setState(() {
            _myAttendanceRecords = myRecords;
            _isLoading = false;
<<<<<<< HEAD
            _error = null;
          });
        }
      } else {
        throw Exception("Failed to load attendance: ${response.statusCode}");
=======
          });
        }
      } else {
        throw Exception("Failed to load attendance.");
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

<<<<<<< HEAD
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isLocationLoading = true;
      _error = null;
    });
    await _initializeData();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "present":
        return const Color(0xFF4CAF50);
      case "absent":
        return const Color(0xFFF44336);
      case "late":
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "present":
        return Icons.check_circle;
      case "absent":
        return Icons.cancel;
      case "late":
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('hh:mm a').format(time);
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';
    return DateFormat('EEEE').format(date);
  }

  Widget _buildTodayCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeBlue, themeBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Today's Attendance",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Location
          _buildTodayInfoRow(
            Icons.location_on_outlined,
            "Current Location",
            _isLocationLoading ? "Loading..." : _currentLocation,
          ),
          const SizedBox(height: 16),

          // Check-in time
          _buildTodayInfoRow(
            Icons.login,
            "Check-In Time",
            _todayCheckIn,
          ),
          const SizedBox(height: 16),

          // Check-out time
          _buildTodayInfoRow(
            Icons.logout,
            "Check-Out Time",
            _todayCheckOut,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
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
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
=======
  Color getStatusColor(String status) {
    if (status == "present") return Colors.green;
    if (status == "absent") return Colors.red;
    return Colors.grey;
  }

  IconData getStatusIcon(String status) {
    if (status == "present") return Icons.check_circle;
    if (status == "absent") return Icons.cancel;
    return Icons.help_outline;
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeBlue,
        title: const Text(
          'My Attendance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: themeBlue,
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: themeBlue,
            strokeWidth: 3,
          ),
        )
            : _error != null
            ? _buildErrorWidget()
            : CustomScrollView(
          slivers: [
            // Today's Card
            SliverToBoxAdapter(
              child: _buildTodayCard(),
            ),

            // History Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Attendance History (Last 7 Days)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),

            // Attendance List
            _myAttendanceRecords.isEmpty
                ? SliverFillRemaining(
              child: _buildEmptyState(),
            )
                : SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = _myAttendanceRecords[index];
                    return _buildAttendanceCard(item);
                  },
                  childCount: _myAttendanceRecords.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord item) {
    final statusColor = getStatusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Optional: Show detail dialog
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Date Circle
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd').format(item.date),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(item.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDayName(item.date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  getStatusIcon(item.status),
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.status[0].toUpperCase() +
                                      item.status.substring(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Time Details
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.login,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check In',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _formatTime(item.checkInTime),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(
                              Icons.logout,
                              size: 16,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check Out',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _formatTime(item.checkOutTime),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No attendance records",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No records found for the last 7 days",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              "Error loading attendance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
=======
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeBlue))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Error: $_error",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _myAttendanceRecords.isEmpty
                  ? Center(
                      child: Text(
                        "No attendance records found for the last 90 days.",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _myAttendanceRecords.length,
                      itemBuilder: (context, index) {
                        final item = _myAttendanceRecords[index];

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              getStatusIcon(item.status),
                              color: getStatusColor(item.status),
                            ),
                            title: Text(
                              DateFormat('EEE, dd MMM yyyy').format(item.date),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              item.status[0].toUpperCase() +
                                  item.status.substring(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(item.status),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
>>>>>>> ec8a31b289309705c4a66d50408ea6b9770f52b3
    );
  }
}