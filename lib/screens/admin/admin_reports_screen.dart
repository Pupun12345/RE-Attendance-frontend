import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart'; 

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

  // ✅ ADDED: State variable for Daily Report Date
  DateTime _dailyDate = DateTime.now();

  // Date range for monthly report
  DateTime? _monthlyFromDate;
  DateTime? _monthlyToDate;

  // ==========================
  // 1. FILE SAVING
  // ==========================
  Future<void> _saveCsvFile(String csvData, String suggestedFileName) async {
  try {
    final List<int> encoded = utf8.encode(csvData);
    final Uint8List bytes = Uint8List.fromList(encoded);

    // ✅ Using 'Link' for better Android compatibility
    await FileSaver.instance.saveFile(
      name: suggestedFileName.replaceAll('.csv', ''),
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Report saved to Downloads folder!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    _showError("Error saving file: ${e.toString()}");
  }
}

  // ==========================
  // 2. DAILY REPORT GENERATOR
  // ==========================
  String _generateDailyCSV(List<dynamic> data) {
  // 1. Sort data by Role (Management -> Supervisor -> Worker)
  data.sort((a, b) {
    int getPriority(String? role) {
      role = role?.toUpperCase() ?? '';
      if (role.contains('MANAGEMENT')) return 1;
      if (role.contains('SUPERVISOR')) return 2;
      return 3; // Worker
    }
    return getPriority(a['user']?['role']).compareTo(getPriority(b['user']?['role']));
  });

  final List<List<dynamic>> rows = [];
  rows.add([
    'SL No.', 'UNIQUE ID', 'DESIGNATION', 'NAME', 'DATE', 
    'PRESENT', 'OT', 'CHECK-IN', 'CHECK-OUT', 
    'LOCATION AREA', 'LOCATION SIZE (LONG-LATIT)'
  ]);

  for (int i = 0; i < data.length; i++) {
    final record = data[i];
    final user = record['user'] ?? {};

    rows.add([
      i + 1,
      user['userId'] ?? 'N/A',
      (user['role'] ?? 'N/A').toString().toUpperCase(),
      user['name'] ?? 'N/A',
      _formatDate(record['date']),
      record['status']?.toUpperCase() ?? 'ABSENT',
      record['ot'] ?? 0,
      _formatTime(record['checkInTime']),
      _formatTime(record['checkOutTime']),
      record['checkInLocation']?['address'] ?? 'KALINGA NAGAR, JAJPUR', // Example from your image
      '${record['checkInLocation']?['longitude'] ?? "0.0"} - ${record['checkInLocation']?['latitude'] ?? "0.0"}',
    ]);
  }
  return const ListToCsvConverter().convert(rows);
}

  // ==========================
  // 3. MONTHLY REPORT GENERATOR
  // ==========================
  // lib/screens/admin/admin_reports_screen.dart

String _generateMonthlySummaryCSV(List<dynamic> data) {
  final Map<String, Map<String, dynamic>> summary = {};
  
  String dateRangeStr = "N/A";
  if (_monthlyFromDate != null && _monthlyToDate != null) {
    dateRangeStr = "${DateFormat('dd/MM').format(_monthlyFromDate!)} - ${DateFormat('dd/MM').format(_monthlyToDate!)}";
  }

  for (var record in data) {
    final user = record['user'] ?? {};
    final String uid = user['userId'] ?? 'Unknown';

    if (!summary.containsKey(uid)) {
      summary[uid] = {
        'uniqueId': uid,
        'name': user['name'] ?? 'N/A',
        'designation': (user['role'] ?? 'WORKER').toString().toUpperCase(),
        'present': 0,
        'absent': 0,
        'holidays': 0,
        'ot': 0,
      };
    }

    // Logic to increment values based on status
    String status = (record['status'] ?? '').toString().toLowerCase();
    if (status == 'present') {
      summary[uid]!['present'] = (summary[uid]!['present'] as int) + 1;
    } else if (status == 'absent') {
      summary[uid]!['absent'] = (summary[uid]!['absent'] as int) + 1;
    }
    
    summary[uid]!['ot'] = (summary[uid]!['ot'] as int) + (record['ot'] ?? 0);
  }

  List<Map<String, dynamic>> sortedList = summary.values.toList();
  sortedList.sort((a, b) {
    int getP(String r) => r.contains('MANAGEMENT') ? 1 : r.contains('SUPERVISOR') ? 2 : 3;
    return getP(a['designation']).compareTo(getP(b['designation']));
  });

  final List<List<dynamic>> rows = [
    ['SL No.', 'UNIQUE ID', 'DESIGNATION', 'NAME', 'FROM DATE - TO DATE', 'PRESENT', 'ABSENT', 'HOLIDAYS', 'OT']
  ];

  for (int i = 0; i < sortedList.length; i++) {
    final item = sortedList[i];
    rows.add([
      i + 1, item['uniqueId'], item['designation'], item['name'],
      dateRangeStr, item['present'], item['absent'], item['holidays'], item['ot']
    ]);
  }
  return const ListToCsvConverter().convert(rows);
}

  // ==========================
  // 4. API HANDLER
  // ==========================
  Future<void> _exportAttendanceReport({
    required String endpoint,
    required String fileNamePrefix,
    required bool isMonthly,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError("Not authorized.");
        return;
      }

      // DEBUG: Print the URL to console to verify the date being sent
      print('Fetching Report: $apiBaseUrl$endpoint');

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
          String csvData;
          if (isMonthly) {
            csvData = _generateMonthlySummaryCSV(data);
          } else {
            csvData = _generateDailyCSV(data);
          }
          final dateTag = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
          final fileName = '${fileNamePrefix}_$dateTag.csv';
          await _saveCsvFile(csvData, fileName);
        }
      } else {
        _showError("Failed to fetch report. Status code: ${response.statusCode}");
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    }
  }

  // ==========================
  // 5. BUTTON ACTIONS
  // ==========================
  Future<void> _exportDailyReport() async {
    if (_isDailyExporting) return;
    setState(() => _isDailyExporting = true);

    // ✅ CHANGED: Use _dailyDate instead of today
    final dateStr = DateFormat('yyyy-MM-dd').format(_dailyDate);
    
    await _exportAttendanceReport(
      endpoint: "/api/v1/reports/attendance/daily?startDate=$dateStr&endDate=$dateStr",
      fileNamePrefix: 'daily_attendance_report',
      isMonthly: false,
    );

    if (mounted) setState(() => _isDailyExporting = false);
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
    final fromStr = DateFormat('yyyy-MM-dd').format(_monthlyFromDate!);
    final toStr = DateFormat('yyyy-MM-dd').format(_monthlyToDate!);

    await _exportAttendanceReport(
      endpoint: "/api/v1/reports/attendance/monthly?startDate=$fromStr&endDate=$toStr",
      fileNamePrefix: 'monthly_attendance_report',
      isMonthly: true,
    );

    if (mounted) setState(() => _isMonthlyExporting = false);
  }

  // ==========================
  // 6. HELPERS & DATE PICKERS
  // ==========================
  Future<void> _pickDailyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dailyDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dailyDate = picked);
    }
  }

  Future<void> _pickMonthlyDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_monthlyFromDate ?? now) : (_monthlyToDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _monthlyFromDate = picked;
          if (_monthlyToDate == null || _monthlyToDate!.isBefore(picked)) {
            _monthlyToDate = picked;
          }
        } else {
          _monthlyToDate = picked;
        }
      });
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(dateStr));
    } catch (_) { return 'N/A'; }
  }

  String _formatTime(dynamic timeStr) {
    if (timeStr == null) return '';
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(timeStr));
    } catch (_) { return ''; }
  }

  String _getPresentStatus(Map<String, dynamic> record) {
    if (record['status'] != null) return record['status'].toString();
    if (record['isPresent'] != null) return record['isPresent'] == true ? 'Present' : 'Absent';
    return 'Absent';
  }

  String _formatLocation(Map<String, dynamic> record) {
    final lat = record['latitude'] ?? record['location']?['latitude'];
    final lng = record['longitude'] ?? record['location']?['longitude'];
    if (lat != null && lng != null) return '$lat - $lng';
    return record['locationSize']?.toString() ?? 'N/A';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ==========================
  // 7. UI BUILD
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
        ),
        title: const Text("Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================== DAILY REPORT CARD ==================
            _buildReportCard(
              title: "Daily Attendance Report",
              icon: LucideIcons.calendarDays,
              desc: "Select a date to download the detailed daily log.",
              isLoading: _isDailyExporting,
              onDownload: _exportDailyReport,
              // ✅ ADDED: Date selector for Daily Report
              extraContent: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickDailyDate,
                  icon: const Icon(LucideIcons.calendar),
                  label: Text(DateFormat('dd-MM-yyyy').format(_dailyDate)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: primaryBlue.withOpacity(0.6))),
                ),
              ),
            ),
            
            // ================== MONTHLY REPORT CARD ==================
            _buildReportCard(
              title: "Monthly Attendance Report",
              icon: LucideIcons.calendarRange,
              desc: "Summary grouped by Management, Supervisor, and Workers.",
              isLoading: _isMonthlyExporting,
              onDownload: _exportMonthlyReport,
              extraContent: _buildDateSelectors(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required String desc,
    required bool isLoading,
    required VoidCallback onDownload,
    Widget? extraContent,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: lightBlue, child: Icon(icon, color: primaryBlue)),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 16))),
            ]),
            const SizedBox(height: 10),
            Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            if (extraContent != null) ...[const SizedBox(height: 12), extraContent],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onDownload,
                icon: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.download, color: Colors.white),
                label: const Text("Download Report", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectors() {
    return Row(
      children: [
        Expanded(child: _dateButton(true)),
        const SizedBox(width: 10),
        Expanded(child: _dateButton(false)),
      ],
    );
  }

  Widget _dateButton(bool isFrom) {
    final date = isFrom ? _monthlyFromDate : _monthlyToDate;
    final label = date != null ? DateFormat('dd-MM-yyyy').format(date) : (isFrom ? "From Date" : "To Date");
    return OutlinedButton(
      onPressed: () => _pickMonthlyDate(isFrom: isFrom),
      style: OutlinedButton.styleFrom(side: BorderSide(color: primaryBlue.withOpacity(0.6))),
      child: Text(label, style: TextStyle(color: date == null ? Colors.black54 : primaryBlue)),
    );
  }
}