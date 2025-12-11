// lib/screens/admin_reports_screen.dart
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

  // 🔹 For monthly report date-range
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
        if (!outputPath.endsWith('.csv')) {
          outputPath += '.csv';
        }
        final File file = File(outputPath);
        await file.writeAsString(csvData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Report saved successfully to $outputPath"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError("File save cancelled.");
      }
    } catch (e) {
      _showError("Error saving file: ${e.toString()}");
    }
  }

  // ==========================
  // 2. CSV GENERATOR
  //    (SAME STRUCTURE FOR DAILY + MONTHLY)
  // ==========================
  String _generateAttendanceCSV(List<dynamic> data) {
    final List<List<dynamic>> rows = [];

    rows.add([
      'No.',
      'UNIQUE ID',
      'DESIGNATION',
      'NAME',
      'DATE',
      'PRESENT',
      'OT',
      'CHECK-IN',
      'CHECK-OUT',
      'LOCATION AREA',
      'LOCATION SIZE',
    ]);

    for (int i = 0; i < data.length; i++) {
      final record = data[i] ?? {};
      final user = record['user'] ?? {};

      final uniqueId =
          user['uniqueId'] ?? user['employeeCode'] ?? user['userId'] ?? 'N/A';

      final designation =
          user['designation'] ?? user['role'] ?? user['userType'] ?? 'N/A';

      final name = user['name'] ?? 'N/A';

      String dateStr = 'N/A';
      if (record['date'] != null) {
        try {
          dateStr =
              DateFormat('dd-MM-yyyy').format(DateTime.parse(record['date']));
        } catch (_) {}
      }

      String presentStatus = 'N/A';
      if (record['status'] != null) {
        presentStatus = record['status'].toString().toUpperCase();
      } else if (record['isPresent'] != null) {
        presentStatus = record['isPresent'] == true ? 'PRESENT' : 'ABSENT';
      }

      final otValue = record['ot'] ??
          record['otHours'] ??
          record['overtime'] ??
          record['otTime'] ??
          0;

      String checkInStr = '';
      if (record['checkInTime'] != null) {
        try {
          checkInStr = DateFormat('hh:mm a')
              .format(DateTime.parse(record['checkInTime']));
        } catch (_) {}
      }

      String checkOutStr = '';
      if (record['checkOutTime'] != null) {
        try {
          checkOutStr = DateFormat('hh:mm a')
              .format(DateTime.parse(record['checkOutTime']));
        } catch (_) {}
      }

      final location = record['location'] ?? {};
      final locationArea =
          record['locationArea'] ?? location['area'] ?? 'N/A';

      String locationSize = 'N/A';
      final lat = record['latitude'] ?? location['latitude'];
      final lng = record['longitude'] ?? location['longitude'];

      if (lat != null && lng != null) {
        locationSize = '$lat - $lng';
      } else if (record['locationSize'] != null) {
        locationSize = record['locationSize'].toString();
      }

      rows.add([
        i + 1,
        uniqueId,
        designation,
        name,
        dateStr,
        presentStatus,
        otValue,
        checkInStr,
        checkOutStr,
        locationArea,
        locationSize,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // ==========================
  // 3. COMMON EXPORT FUNCTION
  // ==========================
  Future<void> _exportAttendanceReport({
    required String endpoint,
    required String fileNamePrefix,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError("Not authorized.");
        return;
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
          _showError("No data found for this report.");
        } else {
          final csvData = _generateAttendanceCSV(data);
          final dateTag =
          DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
          final fileName = '${fileNamePrefix}_$dateTag.csv';
          await _saveCsvFile(csvData, fileName);
        }
      } else {
        _showError(
            "Failed to fetch report. Status code: ${response.statusCode}");
      }
    } catch (e) {
      _showError("An error occurred during export: ${e.toString()}");
    }
  }

  // ==========================
  // 4. DAILY / MONTHLY WRAPPERS
  // ==========================

  /// Daily report:
  /// 👉 Automatically aaj ki date use hogi (startDate = endDate = today)
  Future<void> _exportDailyReport() async {
    if (_isDailyExporting) return;

    setState(() => _isDailyExporting = true);

    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    await _exportAttendanceReport(
      endpoint:
      "/api/v1/reports/attendance/daily?startDate=$todayStr&endDate=$todayStr",
      fileNamePrefix: 'daily_attendance_report',
    );

    if (mounted) {
      setState(() => _isDailyExporting = false);
    }
  }

  /// Monthly report:
  /// 👉 From Date & To Date user pick karega, unke basis pe query jayegi.
  Future<void> _exportMonthlyReport() async {
    if (_isMonthlyExporting) return;

    if (_monthlyFromDate == null || _monthlyToDate == null) {
      _showError("Please select From and To dates for monthly report.");
      return;
    }
    if (_monthlyFromDate!.isAfter(_monthlyToDate!)) {
      _showError("From Date cannot be after To Date.");
      return;
    }

    setState(() => _isMonthlyExporting = true);

    final fromStr = DateFormat('yyyy-MM-dd').format(_monthlyFromDate!);
    final toStr = DateFormat('yyyy-MM-dd').format(_monthlyToDate!);

    // Backend dev yaha par startDate & endDate use karke monthly logic laga sakta hai.
    await _exportAttendanceReport(
      endpoint:
      "/api/v1/reports/attendance/monthly?startDate=$fromStr&endDate=$toStr",
      fileNamePrefix: 'monthly_attendance_report',
    );

    if (mounted) {
      setState(() => _isMonthlyExporting = false);
    }
  }

  // ==========================
  // 5. DATE PICKER HELPERS
  // ==========================

  Future<void> _pickMonthlyDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_monthlyFromDate ?? now)
        : (_monthlyToDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _monthlyFromDate = picked;
          // optional: agar toDate null hai ya from ke pehle hai to toDate bhi sync kar do
          if (_monthlyToDate == null || _monthlyToDate!.isBefore(picked)) {
            _monthlyToDate = picked;
          }
        } else {
          _monthlyToDate = picked;
        }
      });
    }
  }

  // ==========================
  // 6. ERROR SNACKBAR
  // ==========================
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ==========================
  // 7. UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayLabel = DateFormat('dd-MM-yyyy').format(today);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 1,
        centerTitle: true,
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
          "Reports",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 DAILY CARD (always today)
            _buildDailyReportCard(
              todayLabel: todayLabel,
            ),

            // 🔹 MONTHLY CARD (with from/to date pickers)
            _buildMonthlyReportCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ---------- DAILY CARD ----------
  Widget _buildDailyReportCard({
    required String todayLabel,
  }) {
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
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: lightBlue,
                  child: Icon(LucideIcons.calendarDays,
                      color: primaryBlue, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Daily Attendance Report",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Date: $todayLabel (Today)",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Download a detailed CSV report of daily employee attendance records with check-in, check-out, OT and location.",
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isDailyExporting ? null : _exportDailyReport,
                icon: _isDailyExporting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  LucideIcons.download,
                  color: Colors.white,
                ),
                label: const Text(
                  "Download Report",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- MONTHLY CARD ----------
  Widget _buildMonthlyReportCard() {
    String fromLabel = _monthlyFromDate != null
        ? DateFormat('dd-MM-yyyy').format(_monthlyFromDate!)
        : "From Date";

    String toLabel = _monthlyToDate != null
        ? DateFormat('dd-MM-yyyy').format(_monthlyToDate!)
        : "To Date";

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
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: lightBlue,
                  child: Icon(LucideIcons.calendarRange,
                      color: primaryBlue, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Monthly Attendance Report",
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
            Text(
              "Select From and To date (backend will generate monthly/period-wise summary based on this range).",
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Date range row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickMonthlyDate(isFrom: true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryBlue.withOpacity(0.6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                    ),
                    child: Text(
                      fromLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: _monthlyFromDate == null
                            ? Colors.black54
                            : primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickMonthlyDate(isFrom: false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryBlue.withOpacity(0.6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                    ),
                    child: Text(
                      toLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: _monthlyToDate == null
                            ? Colors.black54
                            : primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed:
                _isMonthlyExporting ? null : _exportMonthlyReport,
                icon: _isMonthlyExporting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  LucideIcons.download,
                  color: Colors.white,
                ),
                label: const Text(
                  "Download Report",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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