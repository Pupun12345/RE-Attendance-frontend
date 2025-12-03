// lib/screens/admin_reports_screen.dart
import 'dart:convert'; // ✅ CORRECTED: Use a colon
import 'dart:io'; // ✅ CORRECTED: Use a colon
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart'; 
import 'package:file_picker/file_picker.dart'; 
import 'package:intl/intl.dart'; // ✅ ADDED: For DateFormat
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/admin/admin_reports_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);
  bool _isExporting = false;

  final Map<String, bool> _selectedReports = {
    "Daily Attendance Report": false,
    "Monthly Attendance Summary": false,
    "Complaint Reports": false,
  };

  void _toggleSelection(String key) {
    setState(() {
      _selectedReports[key] = !_selectedReports[key]!;
    });
  }// ✅ --- UPDATED: SAVE CSV FILE HELPER ---
  Future<void> _saveCsvFile(String csvData, String suggestedFileName) async {
    try {
      // 1. Encode the String to Bytes (Required for Android/iOS)
      //    The error happens because mobile platforms need the actual data
      //    to pass to the system's "Save" dialog.
      List<int> list = utf8.encode(csvData);
      Uint8List bytes = Uint8List.fromList(list);

      // 2. Open Save Dialog
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report As',
        fileName: suggestedFileName,
        allowedExtensions: ['csv'],
        type: FileType.custom,
        bytes: bytes, // <--- 🔑 THIS IS THE KEY FIX
      );

      // 3. Handle Success
      if (outputPath != null) {
        // On Mobile: The library handles writing the file when 'bytes' is passed.
        // On Desktop (Windows/Mac): It returns the path, so we must write the file manually.
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
           if (!outputPath.endsWith('.csv')) {
             outputPath += '.csv';
           }
           final File file = File(outputPath);
           await file.writeAsBytes(bytes);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Report saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError("Error saving file: ${e.toString()}");
    }
  }

  // ✅ --- 2. NEW: CSV GENERATOR FUNCTIONS ---
  // (These match your backend controller: reportController.js)

  String _generateDailyAttendanceCSV(List<dynamic> data) {
    final List<List<dynamic>> rows = [];
    // Header row
    rows.add([
      'User ID', 'Name', 'Date', 'Check-In', 'Check-Out', 'Status'
    ]);
    
    // Data rows
    for (var record in data) {
      rows.add([
        record['user']?['userId'] ?? 'N/A',
        record['user']?['name'] ?? 'N/A',
        record['date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date'])) : 'N/A',
        record['checkInTime'] != null ? DateFormat('hh:mm a').format(DateTime.parse(record['checkInTime'])) : '',
        record['checkOutTime'] != null ? DateFormat('hh:mm a').format(DateTime.parse(record['checkOutTime'])) : '',
        record['status'] ?? 'N/A'
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  String _generateMonthlySummaryCSV(List<dynamic> data) {
    final List<List<dynamic>> rows = [];
    // Header row
    rows.add([
      'User ID', 'Name', 'Present Days', 'Absent Days', 'Leave Days'
    ]);
    
    // Data rows
    for (var summary in data) {
      rows.add([
        summary['userId'] ?? 'N/A',
        summary['name'] ?? 'N/A',
        summary['presentDays'] ?? 0,
        summary['absentDays'] ?? 0,
        summary['leaveDays'] ?? 0
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  String _generateComplaintReportCSV(List<dynamic> data) {
    final List<List<dynamic>> rows = [];
    // Header row
    rows.add([
      'Submitted By (ID)', 'Submitted By (Name)', 'Title', 'Description', 'Status', 'Date Submitted'
    ]);
    
    // Data rows
    for (var complaint in data) {
      rows.add([
        complaint['user']?['userId'] ?? 'N/A',
        complaint['user']?['name'] ?? 'N/A',
        complaint['title'] ?? 'N/A',
        complaint['description'] ?? 'N/A',
        complaint['status'] ?? 'N/A',
        complaint['createdAt'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(complaint['createdAt'])) : 'N/A'
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }


  // ✅ --- 3. UPDATED: EXPORT FUNCTION (Ties it all together) ---
  void _exportReports() async {
    final selected = _selectedReports.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selected.isEmpty) {
      _showError("Please select at least one report to export.");
      return;
    }

    setState(() => _isExporting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError("Not authorized.");
        setState(() => _isExporting = false);
        return;
      }

      // NOTE: Your backend requires date queries for some reports.
      // We are using example dates here. You can add Date Pickers
      // to this screen later to let the user choose the range.
      final Map<String, String> reportEndpoints = {
        "Daily Attendance Report": "/api/v1/reports/attendance/daily?startDate=2024-01-01&endDate=2025-12-31",
        "Monthly Attendance Summary": "/api/v1/reports/attendance/monthly?month=11&year=2025",
        "Complaint Reports": "/api/v1/reports/complaints",
      };
      
      List<String> successfulReports = [];

      for (String reportName in selected) {
        if (reportEndpoints.containsKey(reportName)) {
          final url = Uri.parse('$apiBaseUrl${reportEndpoints[reportName]}');
          final response = await http.get(
            url,
            headers: {'Authorization': 'Bearer $token'},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body)['data'];
            String csvData = '';
            String fileName = '';

            // Generate the correct CSV based on the report name
            if (reportName == "Daily Attendance Report") {
              csvData = _generateDailyAttendanceCSV(data);
              fileName = 'daily_attendance_report.csv';
            } else if (reportName == "Monthly Attendance Summary") {
              csvData = _generateMonthlySummaryCSV(data);
              fileName = 'monthly_summary_report.csv';
            } else if (reportName == "Complaint Reports") {
              csvData = _generateComplaintReportCSV(data);
              fileName = 'complaint_report.csv';
            }

            // Save the generated CSV string to a file
            await _saveCsvFile(csvData, fileName);
            successfulReports.add(reportName);
            
          } else {
            _showError("Failed to fetch '${reportName}'.");
          }
        }
      }

      if (successfulReports.isEmpty) {
         _showError("Failed to fetch any reports.");
      }

    } catch (e) {
      _showError("An error occurred during export: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // AppBar is unchanged
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          "Reports", // ✅ Set title
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.bell, color: primaryBlue),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundImage: const AssetImage("assets/images/profile.png"),
              radius: 18,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ],
      ),

      // Body is unchanged
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReportCard(
              icon: LucideIcons.calendarDays,
              title: "Daily Attendance Report",
              description:
                  "Export a detailed CSV report of daily employee attendance records, including check-in and check-out times for a selected period.",
            ),
            _buildReportCard(
              icon: LucideIcons.calendarRange,
              title: "Monthly Attendance Summary",
              description:
                  "Generate a comprehensive monthly attendance summary in CSV format, ideal for payroll and HR analysis.",
            ),
            _buildReportCard(
              icon: LucideIcons.fileText,
              title: "Complaint Reports",
              description:
                  "Access and export a list of submitted complaints, categorized by type and status, for administrative review.",
            ),
            const SizedBox(height: 30),

            // Export Button Section is unchanged
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Finalize Report Export",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportReports, // ✅ Now functional
                icon: _isExporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ))
                    : const Icon(LucideIcons.download, color: Colors.white),
                label: const Text(
                  "Export Selected Reports",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  
  // _buildReportCard helper is unchanged
  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final bool isSelected = _selectedReports[title] ?? false;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: lightBlue,
                  child: Icon(icon, color: primaryBlue, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              description,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Select Button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _toggleSelection(title),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isSelected ? primaryBlue : Colors.grey.shade400,
                  ),
                  backgroundColor:
                      isSelected ? primaryBlue.withOpacity(0.1) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 24),
                ),
                child: Text(
                  isSelected ? "Selected" : "Select",
                  style: TextStyle(
                    color: isSelected ? primaryBlue : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}