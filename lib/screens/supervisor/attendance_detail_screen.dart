import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';

// Model for the employee list
class EmployeeStatus {
  final String id;
  final String name;
  final String status;
  final String? profileImageUrl;

  EmployeeStatus({
    required this.id,
    required this.name,
    required this.status,
    this.profileImageUrl,
  });

  factory EmployeeStatus.fromJson(Map<String, dynamic> json) {
    return EmployeeStatus(
      id: json['_id'],
      name: json['name'],
      status: json['status'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

// Model for self (supervisor) attendance
class SelfAttendanceRecord {
  final DateTime date;
  final String status;
  final String? checkIn;
  final String? checkOut;

  SelfAttendanceRecord({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
  });
}

class AttendanceDetailScreen extends StatefulWidget {
  const AttendanceDetailScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  final String _apiUrl = apiBaseUrl;

  Map<String, dynamic> _summaryData = {};
  List<EmployeeStatus> _employeeList = [];
  bool _isLoading = true;
  String? _error;

  // Self attendance list (supervisor)
  List<SelfAttendanceRecord> _selfAttendanceList = [];

  @override
  void initState() {
    super.initState();
    _initSelfAttendance();
    _fetchData();
  }

  void _initSelfAttendance() {
    final now = DateTime.now();

    _selfAttendanceList = [
      SelfAttendanceRecord(
        date: now,
        status: 'present',
        checkIn: '09:05 AM',
        checkOut: '06:00 PM',
      ),
      SelfAttendanceRecord(
        date: now.subtract(const Duration(days: 1)),
        status: 'present',
        checkIn: '09:10 AM',
        checkOut: '06:05 PM',
      ),
      SelfAttendanceRecord(
        date: now.subtract(const Duration(days: 2)),
        status: 'absent',
        checkIn: null,
        checkOut: null,
      ),
      SelfAttendanceRecord(
        date: now.subtract(const Duration(days: 3)),
        status: 'leave',
        checkIn: null,
        checkOut: null,
      ),
      SelfAttendanceRecord(
        date: now.subtract(const Duration(days: 4)),
        status: 'present',
        checkIn: '09:00 AM',
        checkOut: '05:55 PM',
      ),
      SelfAttendanceRecord(
        date: now.subtract(const Duration(days: 6)),
        status: 'present',
        checkIn: '09:00 AM',
        checkOut: '06:00 PM',
      ),
    ];

    _cleanupOldSelfAttendance();
  }

  void _cleanupOldSelfAttendance() {
    final now = DateTime.now();
    _selfAttendanceList = _selfAttendanceList.where((record) {
      final diff = now.difference(record.date).inDays;
      return diff >= 0 && diff < 5; // keep only last 5 days
    }).toList();

    _selfAttendanceList.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final responses = await Future.wait([
        http.get(
          Uri.parse("$_apiUrl/api/v1/attendance/summary/today"),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse("$_apiUrl/api/v1/attendance/status/today"),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      if (!mounted) return;

      if (responses[0].statusCode == 200) {
        _summaryData = json.decode(responses[0].body)['data'] ?? {};
      } else {
        throw Exception('Failed to load summary');
      }

      if (responses[1].statusCode == 200) {
        final List<dynamic> employeeJson =
            json.decode(responses[1].body)['data'] ?? [];
        _employeeList =
            employeeJson.map((json) => EmployeeStatus.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load employee list');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "Could not connect to server. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),

      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SupervisorDashboardScreen(),
              ),
            );
          },
        ),
        title: const Text(
          "Attendance Detail",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final String presentCount = _summaryData['present']?.toString() ?? '0';
    final String absentCount = _summaryData['absent']?.toString() ?? '0';
    final String leaveCount = _summaryData['leave']?.toString() ?? '0';
    const String lateCount = "0";

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top summary cards
          Row(
            children: [
              buildStatCard("Present", presentCount, Colors.green),
              const SizedBox(width: 10),
              buildStatCard("Absent", absentCount, Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              buildStatCard("Late", lateCount, Colors.orange),
              const SizedBox(width: 10),
              buildStatCard("On Leave", leaveCount, Colors.blueGrey),
            ],
          ),

          const SizedBox(height: 20),

          // Self Attendance heading (updated as requested)
          Text(
            "Self Attendance Record",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: themeBlue,
            ),
          ),
          const SizedBox(height: 10),
          _buildSelfAttendanceSection(),

          const SizedBox(height: 20),

          // Employee List
          const Text(
            "Employee List",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: _employeeList.length,
              itemBuilder: (context, index) {
                final employee = _employeeList[index];
                final statusInfo = _getStatusInfo(employee.status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: employee.profileImageUrl != null
                            ? NetworkImage(employee.profileImageUrl!)
                            : null,
                        child: employee.profileImageUrl == null
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusInfo.text,
                          style: TextStyle(
                            color: statusInfo.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // Self attendance UI
  Widget _buildSelfAttendanceSection() {
    if (_selfAttendanceList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          "No recent records.",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _selfAttendanceList.map((record) {
          final statusInfo = _getStatusInfo(record.status);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                // Date + times
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(record.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildTimeText(record),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusInfo.text,
                    style: TextStyle(
                      color: statusInfo.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _buildTimeText(SelfAttendanceRecord record) {
    if (record.checkIn == null && record.checkOut == null) {
      return "No check-in / check-out";
    }
    return "In: ${record.checkIn ?? '--'}   Out: ${record.checkOut ?? '--'}";
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final d = date.day.toString().padLeft(2, '0');
    final m = monthNames[date.month - 1];
    final y = date.year.toString();
    return "$d $m $y";
  }

  Widget buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
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
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }

  ({Color color, String text}) _getStatusInfo(String status) {
    switch (status) {
      case 'present':
        return (color: Colors.green, text: 'Present');
      case 'absent':
        return (color: Colors.red, text: 'Absent');
      case 'leave':
        return (color: Colors.blueGrey, text: 'On Leave');
      case 'pending':
        return (color: Colors.orange, text: 'Pending');
      case 'rejected':
        return (color: Colors.deepOrange, text: 'Rejected');
      default:
        return (color: Colors.grey, text: 'Unknown');
    }
  }
}
