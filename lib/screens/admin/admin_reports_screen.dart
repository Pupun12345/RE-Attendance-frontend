// lib/screens/admin/admin_reports_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:intl/intl.dart';

import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  bool _isDailyExporting = false;
  bool _isMonthlyExporting = false;

  DateTime? _monthlyFromDate;
  DateTime? _monthlyToDate;

  // ==========================
  // 1. SAVE CSV FILE
  // ==========================
  Future<void> _saveCsvFile(String csvData, String suggestedFileName) async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report As',
        fileName: suggestedFileName,
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );

      if (outputPath != null) {
        if (!outputPath.toLowerCase().endsWith('.csv')) {
          outputPath += '.csv';
        }
        
        final File file = File(outputPath);
        await file.writeAsString(csvData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Report saved to: $outputPath"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      _showError("Error saving file: ${e.toString()}");
    }
  }

  // ==========================
  // 2. CSV GENERATOR: DAILY
  // ==========================
  String _generateDailyCSV(List<dynamic> data) {
    final List<List<dynamic>> rows = [];

    rows.add([
      'S.No', 'User ID', 'Name', 'Role', 'Date', 'Status', 
      'Check-In', 'Check-Out', 'Location', 'Notes'
    ]);

    for (int i = 0; i < data.length; i++) {
      final record = data[i] ?? {};
      final user = record['user'] ?? {};

      final String userId = user['userId'] ?? 'N/A';
      final String name = user['name'] ?? 'N/A';
      final String role = user['role'] ?? 'N/A';
      
      String dateStr = 'N/A';
      if (record['date'] != null) {
        dateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date']));
      }

      final String status = (record['status'] ?? 'Absent').toString().toUpperCase();

      String checkIn = '--:--';
      if (record['checkInTime'] != null) {
        checkIn = DateFormat('hh:mm a').format(DateTime.parse(record['checkInTime']));
      }

      String checkOut = '--:--';
      if (record['checkOutTime'] != null) {
        checkOut = DateFormat('hh:mm a').format(DateTime.parse(record['checkOutTime']));
      }

      final String location = record['checkInLocation'] ?? record['location'] ?? 'N/A';
      final String notes = record['notes'] ?? '';

      rows.add([
        i + 1, userId, name, role, dateStr, status, checkIn, checkOut, location, notes
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // ==========================
  // 3. CSV GENERATOR: MONTHLY (SUMMARY)
  // ==========================
  String _generateMonthlyCSV(List<dynamic> data, String from, String to) {
    final List<List<dynamic>> rows = [];

    rows.add(['Attendance Summary Report', 'From: $from', 'To: $to']);
    rows.add([]); // Empty row for spacing

    rows.add([
      'S.No', 'User ID', 'Name', 'Role', 
      'Present Days', 'Absent Days', 'Leave Days', 'Total Days'
    ]);

    for (int i = 0; i < data.length; i++) {
      final record = data[i] ?? {};

      final String userId = record['userId'] ?? 'N/A';
      final String name = record['name'] ?? 'N/A';
      final String role = record['role'] ?? 'N/A';
      
      final int present = record['presentDays'] ?? 0;
      final int absent = record['absentDays'] ?? 0;
      final int leave = record['leaveDays'] ?? 0;
      final int total = present + absent + leave;

      rows.add([
        i + 1, userId, name, role, present, absent, leave, total
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // ==========================
  // 4. API CALLS
  // ==========================

  Future<void> _exportDailyReport() async {
    if (_isDailyExporting) return;
    setState(() => _isDailyExporting = true);

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final data = await _fetchDataFromApi(
        "/api/v1/reports/attendance/daily?startDate=$todayStr&endDate=$todayStr"
      );

      if (data != null && data.isNotEmpty) {
        final csvData = _generateDailyCSV(data);
        final fileName = 'Daily_Attendance_$todayStr.csv';
        await _saveCsvFile(csvData, fileName);
      }
    } finally {
      if (mounted) setState(() => _isDailyExporting = false);
    }
  }

  Future<void> _exportMonthlyReport() async {
    if (_isMonthlyExporting) return;

    if (_monthlyFromDate == null || _monthlyToDate == null) {
      _showError("Please select From and To dates.");
      return;
    }
    if (_monthlyFromDate!.isAfter(_monthlyToDate!)) {
      _showError("From Date cannot be after To Date.");
      return;
    }

    setState(() => _isMonthlyExporting = true);

    try {
      final fromStr = DateFormat('yyyy-MM-dd').format(_monthlyFromDate!);
      final toStr = DateFormat('yyyy-MM-dd').format(_monthlyToDate!);

      final data = await _fetchDataFromApi(
        "/api/v1/reports/attendance/monthly?startDate=$fromStr&endDate=$toStr"
      );

      if (data != null && data.isNotEmpty) {
        final csvData = _generateMonthlyCSV(data, fromStr, toStr);
        final fileName = 'Summary_Report_${fromStr}_to_$toStr.csv';
        await _saveCsvFile(csvData, fileName);
      }
    } finally {
      if (mounted) setState(() => _isMonthlyExporting = false);
    }
  }

  // Shared API Fetcher
  Future<List<dynamic>?> _fetchDataFromApi(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError("Not authorized. Please login again.");
        return null;
      }

      final url = Uri.parse('$apiBaseUrl$endpoint');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List<dynamic>? ?? [];
        
        if (data.isEmpty) {
          _showError("No data found for the selected period.");
          return null;
        }
        return data;
      } else {
        final err = jsonDecode(response.body);
        _showError(err['message'] ?? "Failed to fetch report.");
        return null;
      }
    } catch (e) {
      _showError("Connection error: $e");
      return null;
    }
  }

  // ==========================
  // 5. UI COMPONENTS
  // ==========================

  Future<void> _pickMonthlyDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_monthlyFromDate ?? now) : (_monthlyToDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _monthlyFromDate = picked;
          if (_monthlyToDate != null && _monthlyToDate!.isBefore(picked)) {
            _monthlyToDate = null;
          }
        } else {
          _monthlyToDate = picked;
        }
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          },
        ),
        title: Text(
          "Reports & Exports",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Daily Report Card ---
            _buildReportCard(
              title: "Daily Attendance Report",
              icon: LucideIcons.calendarDays,
              description: "Download detailed check-in/out records for today ($todayStr).",
              content: Align(
                alignment: Alignment.centerRight,
                child: _buildDownloadButton(
                  onPressed: _isDailyExporting ? null : _exportDailyReport,
                  isLoading: _isDailyExporting,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Monthly/Summary Report Card ---
            _buildReportCard(
              title: "Summary Report",
              icon: LucideIcons.barChart2,
              description: "Select a date range to generate an aggregated attendance summary (Present/Absent counts).",
              content: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDateSelector(true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildDateSelector(false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildDownloadButton(
                      onPressed: _isMonthlyExporting ? null : _exportMonthlyReport,
                      isLoading: _isMonthlyExporting,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required String description,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: lightBlue,
                  radius: 24,
                  child: Icon(icon, color: primaryBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(color: Colors.black54, height: 1.4)),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(bool isFrom) {
    final date = isFrom ? _monthlyFromDate : _monthlyToDate;
    final label = date != null ? DateFormat('dd/MM/yyyy').format(date) : (isFrom ? "Start Date" : "End Date");
    
    return GestureDetector(
      onTap: () => _pickMonthlyDate(isFrom: isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 18, color: primaryBlue),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: date == null ? Colors.grey : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton({required VoidCallback? onPressed, required bool isLoading}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : const Icon(LucideIcons.download, color: Colors.white, size: 20),
      label: const Text("Download CSV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}