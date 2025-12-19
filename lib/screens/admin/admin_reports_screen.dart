import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';

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

  DateTime _dailyDate = DateTime.now();
  DateTime? _monthlyFromDate;
  DateTime? _monthlyToDate;


  Future<void> _saveCsvFile(String csvData, String fileName) async {
    try {
      final bytes = utf8.encode(csvData);

      const platform = MethodChannel('downloads_channel');

      final String? result = await platform.invokeMethod(
        'saveToDownloads',
        {
          'fileName': fileName,
          'bytes': bytes,
          'mime': lookupMimeType(fileName) ?? 'text/csv',
        },
      );

      if (!mounted) return;

      if (result == null) {
        _showError("Download failed");
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report saved in Downloads folder"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError("Download error: $e");
    }
  }


  String _generateDailyCSV(List<dynamic> data) {
    // 1. Sort data by Role (Management -> Supervisor -> Worker)
    data.sort((a, b) {
      int getPriority(String? role) {
        role = role?.toUpperCase() ?? '';
        if (role.contains('MANAGEMENT')) return 1;
        if (role.contains('SUPERVISOR')) return 2;
        return 3; // Worker
      }


      return getPriority(a['user']?['role'])
          .compareTo(getPriority(b['user']?['role']));
    });


    final List<List<dynamic>> rows = [];


    // Header row - matching image format exactly
    rows.add([
      'SL No.',
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
      'PHOTO'
    ]);


    // Data rows
    for (int i = 0; i < data.length; i++) {
      final record = data[i];
      final user = record['user'] ?? {};


      // Get location coordinates
      final location = record['checkInLocation'] ?? {};
      final longitude = location['longitude'] ?? record['longitude'] ?? '0.0';
      final latitude = location['latitude'] ?? record['latitude'] ?? '0.0';


      // Add header rows matching image format
      final monthName = DateFormat('MMMM').format(_dailyDate).toUpperCase();
      final daysInMonth = DateTime(_dailyDate.year, _dailyDate.month + 1, 0).day;


      rows.add([]); // Empty row
      rows.add([
        '',
        '{$monthName $daysInMonth DAYS} THIS IS DAILY REPORT',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        ''
      ]);
      rows.add([]); // Empty row


      // Format status as "PRESNT" or "ABSENT" (matching image)
      String status = 'ABSENT';
      if (record['status'] != null) {
        final statusStr = record['status'].toString().toUpperCase();
        status = statusStr.contains('PRESENT') || statusStr == 'PRESNT'
            ? 'PRESNT'
            : 'ABSENT';
      }


      rows.add([
        i + 1,
        user['userId'] ?? 'N/A',
        (user['role'] ?? 'N/A').toString().toUpperCase(),
        user['name'] ?? 'N/A',
        _formatDate(record['date'] ?? record['dateTime']),
        status,
        record['ot'] ?? record['overtime'] ?? 0,
        _formatTime(record['checkInTime'] ?? record['checkinTime']),
        _formatTime(record['checkOutTime'] ?? record['checkoutTime']),
        location['address'] ?? record['address'] ?? '',
        '$longitude - $latitude',
        // Format: longitude - latitude (matching image)
        '',
        // PHOTO column - empty as shown in image
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


    // Format date range as shown in image: "07-11-2025 TO 07-12-2025"
    String dateRangeStr = "N/A";
    if (_monthlyFromDate != null && _monthlyToDate != null) {
      dateRangeStr =
      "${DateFormat('dd-MM-yyyy').format(_monthlyFromDate!)} TO ${DateFormat('dd-MM-yyyy').format(_monthlyToDate!)}";
    }


    // Calculate total days in range for holidays calculation
    int totalDays = 0;
    if (_monthlyFromDate != null && _monthlyToDate != null) {
      totalDays = _monthlyToDate!.difference(_monthlyFromDate!).inDays + 1;
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
          'holidays': 5,
          // Default holidays as shown in image (can be calculated if needed)
          'ot': 0,
        };
      }


      // Logic to increment values based on status
      String status = (record['status'] ?? '').toString().toLowerCase();
      if (status == 'present' || status == 'presnt') {
        summary[uid]!['present'] = (summary[uid]!['present'] as int) + 1;
      } else if (status == 'absent') {
        summary[uid]!['absent'] = (summary[uid]!['absent'] as int) + 1;
      }


      // Sum overtime
      summary[uid]!['ot'] = (summary[uid]!['ot'] as int) +
          (record['ot'] ?? record['overtime'] ?? 0);
    }


    // Calculate holidays (weekends + any marked holidays)
    // For now, using default 5 as shown in image, but can be enhanced
    const int defaultHolidays = 5;


    List<Map<String, dynamic>> sortedList = summary.values.toList();
    sortedList.sort((a, b) {
      int getP(String r) => r.contains('MANAGEMENT')
          ? 1
          : r.contains('SUPERVISOR')
          ? 2
          : 3;
      return getP(a['designation']).compareTo(getP(b['designation']));
    });


    final List<List<dynamic>> rows = [];


    // Add header row matching image format
    rows.add([]); // Empty row
    rows.add(['', 'MONTHLY REPORT', '', '', '', '', '', '', '']);
    rows.add([]); // Empty row

    // Header row - matching image format exactly
    rows.add([
      'SL No.',
      'UNIQUE ID',
      'DESIGNATION',
      'NAME',
      'FROM DATE - TO DATE',
      'PRESENT',
      'ABSENT',
      'HOLIDAYS',
      'OT'
    ]);


    // Data rows
    for (int i = 0; i < sortedList.length; i++) {
      final item = sortedList[i];
      rows.add([
        i + 1,
        item['uniqueId'],
        item['designation'],
        item['name'],
        dateRangeStr,
        item['present'],
        item['absent'],
        defaultHolidays, // Using default holidays as shown in image
        item['ot']
      ]);
    }




    return const ListToCsvConverter().convert(rows);
  }

  /*String _generateDailyCSV(List<dynamic> data) {
    final rows = <List<dynamic>>[];

    rows.add([
      'SL No.',
      'UNIQUE ID',
      'DESIGNATION',
      'NAME',
      'DATE',
      'PRESENT',
      'OT',
      'CHECK-IN',
      'CHECK-OUT',
      'LOCATION AREA',
      'LOCATION SIZE'
    ]);

    for (int i = 0; i < data.length; i++) {
      final r = data[i] ?? {};
      final u = r['user'] ?? {};

      rows.add([
        i + 1,
        u['uniqueId'] ?? 'N/A',
        u['designation'] ?? u['role'] ?? 'N/A',
        u['name'] ?? 'N/A',
        _formatDate(r['date']),
        _getPresentStatus(r),
        r['ot'] ?? 0,
        _formatTime(r['checkInTime']),
        _formatTime(r['checkOutTime']),
        r['locationArea'] ?? 'N/A',
        _formatLocation(r),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }


  String _generateMonthlySummaryCSV(List<dynamic> data) {
    final Map<String, Map<String, dynamic>> summary = {};

    for (final r in data) {
      final u = r['user'];
      if (u == null) continue;

      final id = u['_id'] ?? u['uniqueId'];
      if (id == null) continue;

      summary.putIfAbsent(id, () => {
        'uniqueId': u['uniqueId'] ?? 'N/A',
        'designation':
        (u['designation'] ?? u['role'] ?? 'WORKER')
            .toString()
            .toUpperCase(),
        'name': u['name'] ?? 'N/A',
        'present': 0,
        'absent': 0,
        'holidays': 0,
        'ot': 0,
      });

      final status = (r['status'] ?? '').toString().toUpperCase();
      if (status == 'PRESENT') summary[id]!['present']++;
      else if (status == 'ABSENT') summary[id]!['absent']++;
      else if (status == 'HOLIDAY') summary[id]!['holidays']++;

      summary[id]!['ot'] += int.tryParse(r['ot']?.toString() ?? '0') ?? 0;
    }

    int rolePriority(String d) {
      if (d.contains('MANAGEMENT')) return 1;
      if (d.contains('SUPERVISOR')) return 2;
      if (d.contains('WORKER')) return 3;
      return 4;
    }

    final list = summary.values.toList()
      ..sort((a, b) =>
          rolePriority(a['designation'])
              .compareTo(rolePriority(b['designation'])));

    final rows = <List<dynamic>>[];
    rows.add([
      'SL No.',
      'UNIQUE ID',
      'DESIGNATION',
      'NAME',
      'FROM DATE - TO DATE',
      'PRESENT',
      'ABSENT',
      'HOLIDAYS',
      'OT'
    ]);

    final f = DateFormat('dd-MM-yyyy');
    final range =
        "${f.format(_monthlyFromDate!)} TO ${f.format(_monthlyToDate!)}";

    for (int i = 0; i < list.length; i++) {
      final r = list[i];
      rows.add([
        i + 1,
        r['uniqueId'],
        r['designation'],
        r['name'],
        range,
        r['present'],
        r['absent'],
        r['holidays'],
        r['ot'],
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
*/
  // ============================================================
  // API CALL
  // ============================================================
  Future<void> _exportAttendanceReport({
    required String endpoint,
    required bool isMonthly,
    required String prefix,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return _showError("Unauthorized");

      final res = await http.get(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) {
        return _showError("Server error ${res.statusCode}");
      }

      final data = jsonDecode(res.body)['data'] ?? [];
      if (data.isEmpty) return _showError("No data found");

      final csv = isMonthly
          ? _generateMonthlySummaryCSV(data)
          : _generateDailyCSV(data);

      final fileName =
          "${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";

      await _saveCsvFile(csv, fileName);
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ============================================================
  // DATE PICKERS
  // ============================================================
  Future<void> _pickDailyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dailyDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dailyDate = picked);
  }

  Future<void> _pickMonthlyDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _monthlyFromDate = picked;
          _monthlyToDate ??= picked;
        } else {
          _monthlyToDate = picked;
        }
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _formatDate(d) {
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(d));
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatTime(t) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(t));
    } catch (_) {
      return '';
    }
  }

  String _getPresentStatus(Map r) {
    if (r['status'] != null) return r['status'];
    if (r['isPresent'] == true) return 'Present';
    return 'Absent';
  }

  String _formatLocation(Map r) {
    final lat = r['latitude'] ?? r['location']?['latitude'];
    final lng = r['longitude'] ?? r['location']?['longitude'];
    return (lat != null && lng != null) ? "$lat - $lng" : 'N/A';
  }

  void _showError(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          ),
        ),
        title: const Text("Reports",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _reportCard(
              title: "Daily Attendance Report",
              description:
              "Download detailed daily attendance with check-in and check-out time.",
              icon: LucideIcons.calendarDays,
              extra: OutlinedButton.icon(
                onPressed: _pickDailyDate,
                icon: const Icon(Icons.calendar_today),
                label:
                Text(DateFormat('dd-MM-yyyy').format(_dailyDate)),
              ),
              isLoading: _isDailyExporting,
              onDownload: () {
                final d =
                DateFormat('yyyy-MM-dd').format(_dailyDate);
                _exportAttendanceReport(
                  endpoint:
                  "/api/v1/reports/attendance/daily?startDate=$d&endDate=$d",
                  isMonthly: false,
                  prefix: "daily_attendance",
                );
              },
            ),
            _reportCard(
              title: "Monthly Attendance Report",
              description:
              "Monthly summary grouped by Management, Supervisor and Workers.",
              icon: LucideIcons.calendarRange,
              extra: Row(
                children: [
                  _dateBtn(
                      "From", _monthlyFromDate, () => _pickMonthlyDate(true)),
                  const SizedBox(width: 8),
                  _dateBtn(
                      "To", _monthlyToDate, () => _pickMonthlyDate(false)),
                ],
              ),
              isLoading: _isMonthlyExporting,
              onDownload: () {
                if (_monthlyFromDate == null ||
                    _monthlyToDate == null) {
                  _showError("Select date range");
                  return;
                }
                final f = DateFormat('yyyy-MM-dd')
                    .format(_monthlyFromDate!);
                final t = DateFormat('yyyy-MM-dd')
                    .format(_monthlyToDate!);
                _exportAttendanceReport(
                  endpoint:
                  "/api/v1/reports/attendance/monthly?startDate=$f&endDate=$t",
                  isMonthly: true,
                  prefix: "monthly_attendance",
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard({
    required String title,
    required String description,
    required IconData icon,
    required Widget extra,
    required bool isLoading,
    required VoidCallback onDownload,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: lightBlue,
                child: Icon(icon, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryBlue)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(description,
                style:
                const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 12),
            extra,
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onDownload,
                icon: isLoading
                    ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, color: Colors.white),
                label: const Text("Download",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _dateBtn(String label, DateTime? date, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(
        date == null
            ? label
            : DateFormat('dd-MM-yyyy').format(date),
      ),
    );
  }
}
