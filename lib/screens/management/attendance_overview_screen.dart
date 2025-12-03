// lib/screens/management/attendance_overview_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // ✅ --- THIS WAS THE BROKEN LINE ---
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

// 1. A Model to hold the fetched attendance data
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
      id: json['_id'],
      status: json['status'],
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
    );
  }
}

// 2. Convert to StatefulWidget to fetch data
class AttendanceOverviewScreen extends StatefulWidget {
  const AttendanceOverviewScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceOverviewScreen> createState() =>
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  final Color themeBlue = const Color(0xFF0A3C7B);
  List<AttendanceRecord> _myAttendanceRecords = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyAttendance();
  }

  // lib/screens/management/attendance_overview_screen.dart

  // ... (keep your imports and AttendanceRecord class as they are) ...

  Future<void> _fetchMyAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userString = prefs.getString('user');

      if (token == null || userString == null) {
        throw Exception("Not authorized.");
      }

      final Map<String, dynamic> myUser = jsonDecode(userString);
      final String myUserId = myUser['id'] ?? myUser['_id']; // Handle both ID formats

      // Use a robust date range (e.g., past 90 days)
      final String endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String startDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 90)));

      final url = Uri.parse(
          '$apiBaseUrl/api/v1/reports/attendance/daily?startDate=$startDate&endDate=$endDate');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allRecords = data['data'];

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
            .map((record) => AttendanceRecord.fromJson(record))
            .toList();

        // Sort by date (newest first)
        myRecords.sort((a, b) => b.date.compareTo(a.date));

        if (mounted) {
          setState(() {
            _myAttendanceRecords = myRecords;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load attendance.");
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

  Color getStatusColor(String status) {
    if (status == "present") return Colors.green;
    if (status == "absent") return Colors.red;
    return Colors.grey;
  }

  IconData getStatusIcon(String status) {
    if (status == "present") return Icons.check_circle;
    if (status == "absent") return Icons.cancel;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}