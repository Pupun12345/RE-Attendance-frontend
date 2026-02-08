// lib/screens/admin_summary_dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/admin/admin_pending_attendance_screen.dart';
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';

class AdminSummaryDashboardScreen extends StatefulWidget {
  const AdminSummaryDashboardScreen({super.key});

  @override
  State<AdminSummaryDashboardScreen> createState() =>
      _AdminSummaryDashboardScreenState();
}

class _AdminSummaryDashboardScreenState
    extends State<AdminSummaryDashboardScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color greyBackground = const Color(0xFFF5F5F5);

  // 🔹 Fields will be loaded from API
  int totalSupervisors = 0;
  int totalWorkers = 0;
  int totalManagement = 0;
  int presentToday = 0;
  int absentToday = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ✅ --- FETCH ALL DASHBOARD DATA ---
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError("Not authorized.");
        return;
      }

      final headers = {'Authorization': 'Bearer $token'};

      // --- 1. Fetch User Counts ---
      final usersUrl = Uri.parse('$apiBaseUrl/api/v1/users');
      final usersResponse = await http.get(usersUrl, headers: headers);

      int supervisors = 0;
      int workers = 0;
      int management = 0;

      if (usersResponse.statusCode == 200) {
        final data = jsonDecode(usersResponse.body);
        final users = data['users'] as List;
        supervisors = users.where((u) => u['role'] == 'supervisor').length;
        workers = users.where((u) => u['role'] == 'worker').length;
        management = users.where((u) => u['role'] == 'management').length;
      } else {
        _showError("Failed to load user data.");
      }

      // --- 2. Fetch Attendance Summary ---
      final summaryUrl =
      Uri.parse('$apiBaseUrl/api/v1/attendance/summary/today');
      final summaryResponse = await http.get(summaryUrl, headers: headers);

      int present = 0;
      int absent = 0;

      if (summaryResponse.statusCode == 200) {
        final data = jsonDecode(summaryResponse.body);
        present = data['data']['present'] ?? 0;
        absent = data['data']['absent'] ?? 0;
      } else {
        _showError("Failed to load attendance summary.");
      }

      // --- 3. Update State Once ---
      setState(() {
        totalSupervisors = supervisors;
        totalWorkers = workers;
        totalManagement = management;
        presentToday = present;
        absentToday = absent;
      });
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ --- SHOW ERROR SNACKBAR ---
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // 🔹 Edit Value Dialog (No longer used for Present/Absent)
  void _editValue(String title, int currentValue, Function(int) onUpdate) {
    // not used now
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 1,
        centerTitle: true,

        // 🔙 Back icon → AdminDashboardScreen
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDashboardScreen(),
              ),
            );
          },
        ),

        title: const Text(
          "Dashboard Summary",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.bell, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔹 Top Row — Supervisors & Workers
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      icon: LucideIcons.userCog,
                      title: "Total Supervisors",
                      value: totalSupervisors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      icon: LucideIcons.users,
                      title: "Total Workers",
                      value: totalWorkers,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 🔹 Management
              _buildInfoCard(
                icon: LucideIcons.briefcase,
                title: "Total Management",
                value: totalManagement,
              ),

              const SizedBox(height: 16),

              // 🔹 Attendance Summary
              _buildAttendanceCard(),

              const SizedBox(height: 16),

              // 🔹 Pending Attendance Card
              _buildPendingAttendanceCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Info Card Widget
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required int value,
    VoidCallback? onEdit,
  }) {
    return GestureDetector(
      onTap: onEdit,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: lightBlue,
                child: Icon(icon, color: primaryBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                Icon(LucideIcons.edit, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Attendance Summary Card
  Widget _buildAttendanceCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Attendance",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAttendanceItem(
                  icon: LucideIcons.checkCircle,
                  color: Colors.green,
                  label: "Present",
                  value: presentToday,
                ),
                _buildAttendanceItem(
                  icon: LucideIcons.xCircle,
                  color: Colors.redAccent,
                  label: "Absent",
                  value: absentToday,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Pending Attendance Card (only title + arrow)
  Widget _buildPendingAttendanceCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminPendingAttendanceScreen(),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: lightBlue,
                child: Icon(
                  LucideIcons.clock,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "Pending Attendance",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryBlue,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Attendance Stat Item
  Widget _buildAttendanceItem({
    required IconData icon,
    required Color color,
    required String label,
    required int value,
    VoidCallback? onTap, // optional
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
