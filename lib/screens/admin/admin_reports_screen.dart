
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:smartcare_app/utils/file_saver_mobile.dart'
if (dart.library.html) 'package:smartcare_app/utils/file_saver_web.dart';
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


  int _monthlyHolidaysCount = 0;


  Future<void> _saveCsvFile(String csvData, String fileName) async {
    try {
      if (kIsWeb) {
        saveCsvWeb(csvData, fileName);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Report downloaded successfully"),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

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




  String _generateMonthlyDetailedCSV(List<dynamic> data) {
    // Sort by role priority
    data.sort((a, b) {
      int p(String? r) {
        r = r?.toUpperCase() ?? '';
        if (r.contains('MANAGEMENT')) return 1;
        if (r.contains('SUPERVISOR')) return 2;
        return 3; // Worker
      }

      return p(a['user']?['role']).compareTo(p(b['user']?['role']));
    });

    final rows = <List<dynamic>>[];

    // Date range for header
    String range = '';
    if (_monthlyFromDate != null && _monthlyToDate != null) {
      range = "${DateFormat('dd-MM-yyyy').format(_monthlyFromDate!)} TO ${DateFormat('dd-MM-yyyy').format(_monthlyToDate!)}";
    }

    // ✅ Title rows with holidays count
    rows.add([]);
    rows.add([
      '',
      'MONTHLY ATTENDANCE SUMMARY REPORT ($range)',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);
    rows.add([
      '',
      'Total Holidays in Period: $_monthlyHolidaysCount',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);
    rows.add([]);

    // ✅ Header row - SUMMARY format with HOLIDAYS column
    rows.add([
      'SL No.',
      'UNIQUE ID',
      'DESIGNATION',
      'NAME',
      'PRESENT DAYS',
      'ABSENT DAYS',
      'LEAVE DAYS',
      'HOLIDAYS',
      'LATE DAYS',
      'TOTAL OT HOURS',
    ]);

    // Data rows
    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final u = r['user'] ?? {};

      rows.add([
        i + 1,
        u['userId'] ?? 'N/A',
        (u['role'] ?? 'N/A').toString().toUpperCase(),
        u['name'] ?? 'N/A',
        r['presentDays'] ?? 0,
        r['absentDays'] ?? 0,
        r['leaveDays'] ?? 0,
        _monthlyHolidaysCount, // ✅ Show holidays count for each row
        r['lateDays'] ?? 0,
        r['overtimeHours'] ?? r['overtime'] ?? r['ot'] ?? 0,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<void> _exportAttendanceReport({
    required String endpoint,
    required bool isMonthly,
    required String prefix,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ TOKEN NOT FOUND");
        return _showError("Unauthorized");
      }

      final url = '$apiBaseUrl$endpoint';



      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // 🔹 PRINT RESPONSE DETAILS
      print("📥 RESPONSE START ====================");
      print("✅ STATUS CODE => ${res.statusCode}");
      print("📦 RAW BODY   => ${res.body}");
      print("📥 RESPONSE END ======================");

      if (res.statusCode != 200) {
        return _showError("Server error ${res.statusCode}");
      }

      final decoded = jsonDecode(res.body);

      // 🔹 PRINT DECODED JSON
      print("🧩 DECODED JSON => $decoded");

      final data = decoded['data'] ?? [];

      // ✅ EXTRACT HOLIDAYS COUNT FROM API RESPONSE (only for monthly)
      if (isMonthly) {
        _monthlyHolidaysCount = decoded['holidaysCount'] ?? 0;
        print("🎉 HOLIDAYS COUNT => $_monthlyHolidaysCount");
      }

      print("📊 DATA COUNT => ${data.length}");
      if (data.isNotEmpty) {
        print("📄 FIRST RECORD => ${data.first}");
      }

      if (data.isEmpty) {
        return _showError("No data found");
      }

      final csv = isMonthly
          ? _generateMonthlyDetailedCSV(data)
          : _generateDailyCSV(data);

      final fileName =
          "${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";

      print("📝 CSV FILE NAME => $fileName");

      await _saveCsvFile(csv, fileName);
    } catch (e) {
      print("❌ EXPORT ERROR => $e");
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
// HELPERS - FIXED FOR TIMEZONE
// ============================================================

  String _formatDate(dynamic d) {
    if (d == null) return 'N/A';

    try {
      DateTime dateTime;

      // Parse the date string
      if (d is String) {
        dateTime = DateTime.parse(d);
      } else if (d is DateTime) {
        dateTime = d;
      } else {
        return 'N/A';
      }

      // Convert UTC to local timezone (IST)
      if (dateTime.isUtc) {
        dateTime = dateTime.toLocal();
      }

      return DateFormat('dd-MM-yyyy').format(dateTime);
    } catch (e) {
      print("❌ Date format error: $e for value: $d");
      return 'N/A';
    }
  }

  String _formatTime(dynamic t) {
    if (t == null) return '';

    try {
      DateTime dateTime;

      // Parse the time string
      if (t is String) {
        dateTime = DateTime.parse(t);
      } else if (t is DateTime) {
        dateTime = t;
      } else {
        return '';
      }

      // Convert UTC to local timezone (IST)
      if (dateTime.isUtc) {
        dateTime = dateTime.toLocal();
      }

      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      print("❌ Time format error: $e for value: $t");
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
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: Colors.red)
    );
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

//
//
//
//
//
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
//
// import 'package:smartcare_app/utils/file_saver_mobile.dart'
// if (dart.library.html) 'package:smartcare_app/utils/file_saver_web.dart';
//
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:csv/csv.dart';
// import 'package:intl/intl.dart';
// import 'package:mime/mime.dart';
//
// import 'package:smartcare_app/utils/constants.dart';
// import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';
//
// class AdminReportsScreen extends StatefulWidget {
//   const AdminReportsScreen({super.key});
//
//   @override
//   State<AdminReportsScreen> createState() => _AdminReportsScreenState();
// }
//
// class _AdminReportsScreenState extends State<AdminReportsScreen> {
//   final Color primaryBlue = const Color(0xFF0D47A1);
//   final Color lightBlue = const Color(0xFFE3F2FD);
//
//   bool _isDailyExporting = false;
//   bool _isMonthlyExporting = false;
//
//   DateTime _dailyDate = DateTime.now();
//   DateTime? _monthlyFromDate;
//   DateTime? _monthlyToDate;
//
//
//   Future<void> _saveCsvFile(String csvData, String fileName) async {
//     try {
//       // ==========================
//       // 🌐 WEB
//       // ==========================
//       if (kIsWeb) {
//         saveCsvWeb(csvData, fileName);
//
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Report downloaded successfully"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         return;
//       }
//
//       // ==========================
//       // 📱 ANDROID / IOS
//       // ==========================
//       final bytes = utf8.encode(csvData);
//
//       const platform = MethodChannel('downloads_channel');
//
//       final String? result = await platform.invokeMethod(
//         'saveToDownloads',
//         {
//           'fileName': fileName,
//           'bytes': bytes,
//           'mime': lookupMimeType(fileName) ?? 'text/csv',
//         },
//       );
//
//       if (!mounted) return;
//
//       if (result == null) {
//         _showError("Download failed");
//         return;
//       }
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Report saved in Downloads folder"),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       _showError("Download error: $e");
//     }
//   }
//
//
//
//
//   String _generateDailyCSV(List<dynamic> data) {
//     // 1. Sort data by Role (Management -> Supervisor -> Worker)
//     data.sort((a, b) {
//       int getPriority(String? role) {
//         role = role?.toUpperCase() ?? '';
//         if (role.contains('MANAGEMENT')) return 1;
//         if (role.contains('SUPERVISOR')) return 2;
//         return 3; // Worker
//       }
//
//
//       return getPriority(a['user']?['role'])
//           .compareTo(getPriority(b['user']?['role']));
//     });
//
//
//     final List<List<dynamic>> rows = [];
//
//     final monthName = DateFormat('MMMM').format(_dailyDate).toUpperCase();
//     final daysInMonth = DateTime(_dailyDate.year, _dailyDate.month + 1, 0).day;
//
//
//     rows.add([]); // Empty row
//     rows.add([
//       '',
//       '{$monthName $daysInMonth DAYS} THIS IS DAILY REPORT',
//       '',
//       '',
//       '',
//       '',
//       '',
//       '',
//       '',
//       '',
//       '',
//       ''
//     ]);
//     rows.add([]); // Empty row
//
//     // Header row - matching image format exactly
//     rows.add([
//       'SL No.',
//       'UNIQUE ID',
//       'DESIGNATION',
//       'NAME',
//       'DATE',
//       'PRESENT',
//       'OT',
//       'CHECK-IN',
//       'CHECK-OUT',
//       'LOCATION AREA',
//       'LOCATION SIZE',
//       'PHOTO'
//     ]);
//
//
//     // Data rows
//     for (int i = 0; i < data.length; i++) {
//       final record = data[i];
//       final user = record['user'] ?? {};
//
//
//       // Get location coordinates
//       final location = record['checkInLocation'] ?? {};
//       final longitude = location['longitude'] ?? record['longitude'] ?? '0.0';
//       final latitude = location['latitude'] ?? record['latitude'] ?? '0.0';
//
//
//       // Format status as "PRESNT" or "ABSENT" (matching image)
//       String status = 'ABSENT';
//       if (record['status'] != null) {
//         final statusStr = record['status'].toString().toUpperCase();
//         status = statusStr.contains('PRESENT') || statusStr == 'PRESNT'
//             ? 'PRESNT'
//             : 'ABSENT';
//       }
//
//
//       rows.add([
//         i + 1,
//         user['userId'] ?? 'N/A',
//         (user['role'] ?? 'N/A').toString().toUpperCase(),
//         user['name'] ?? 'N/A',
//         _formatDate(record['date'] ?? record['dateTime']),
//         status,
//         record['ot'] ?? record['overtime'] ?? 0,
//         _formatTime(record['checkInTime'] ?? record['checkinTime']),
//         _formatTime(record['checkOutTime'] ?? record['checkoutTime']),
//         location['address'] ?? record['address'] ?? '',
//         '$longitude - $latitude',
//         // Format: longitude - latitude (matching image)
//         '',
//         // PHOTO column - empty as shown in image
//       ]);
//     }
//
//
//
//
//
//     return const ListToCsvConverter().convert(rows);
//   }
//
//
//
//
//   String _generateMonthlyDetailedCSV(List<dynamic> data) {
//     // Sort by role priority
//     data.sort((a, b) {
//       int p(String? r) {
//         r = r?.toUpperCase() ?? '';
//         if (r.contains('MANAGEMENT')) return 1;
//         if (r.contains('SUPERVISOR')) return 2;
//         return 3; // Worker
//       }
//
//       return p(a['user']?['role']).compareTo(p(b['user']?['role']));
//     });
//
//     final rows = <List<dynamic>>[];
//
//     // Date range for header
//     String range = '';
//     if (_monthlyFromDate != null && _monthlyToDate != null) {
//       range = "${DateFormat('dd-MM-yyyy').format(_monthlyFromDate!)} TO ${DateFormat('dd-MM-yyyy').format(_monthlyToDate!)}";
//     }
//
//     // Title rows
//     rows.add([]);
//     rows.add([
//       '',
//       'MONTHLY ATTENDANCE SUMMARY REPORT ($range)',
//       '',
//       '',
//       '',
//       '',
//       '',
//       '',
//       '',
//     ]);
//     rows.add([]);
//
//     // Header row - SUMMARY format
//     rows.add([
//       'SL No.',
//       'UNIQUE ID',
//       'DESIGNATION',
//       'NAME',
//       'PRESENT DAYS',
//       'ABSENT DAYS',
//       'LEAVE DAYS',
//       'LATE DAYS',
//       'TOTAL OT HOURS',
//     ]);
//
//     // Data rows
//     for (int i = 0; i < data.length; i++) {
//       final r = data[i];
//       final u = r['user'] ?? {};
//
//       rows.add([
//         i + 1,
//         u['userId'] ?? 'N/A',
//         (u['role'] ?? 'N/A').toString().toUpperCase(),
//         u['name'] ?? 'N/A',
//         r['presentDays'] ?? 0,
//         r['absentDays'] ?? 0,
//         r['leaveDays'] ?? 0,
//         r['lateDays'] ?? 0,
//         r['overtimeHours'] ?? r['overtime'] ?? r['ot'] ?? 0,
//       ]);
//     }
//
//     return const ListToCsvConverter().convert(rows);
//   }
//   // String _generateMonthlyDetailedCSV(List<dynamic> data) {
//   //   // Sort by role priority
//   //   data.sort((a, b) {
//   //     int p(String? r) {
//   //       r = r?.toUpperCase() ?? '';
//   //       if (r.contains('MANAGEMENT')) return 1;
//   //       if (r.contains('SUPERVISOR')) return 2;
//   //       return 3;
//   //     }
//   //
//   //     return p(a['user']?['role']).compareTo(p(b['user']?['role']));
//   //   });
//   //
//   //   final rows = <List<dynamic>>[];
//   //
//   //   String range = '';
//   //   if (_monthlyFromDate != null && _monthlyToDate != null) {
//   //     range =
//   //     "${DateFormat('dd-MM-yyyy').format(_monthlyFromDate!)} TO ${DateFormat('dd-MM-yyyy').format(_monthlyToDate!)}";
//   //   }
//   //
//   //   rows.add([]);
//   //   rows.add([
//   //     '',
//   //     'MONTHLY ATTENDANCE REPORT ($range)',
//   //     '',
//   //     '',
//   //     '',
//   //     '',
//   //     '',
//   //     '',
//   //     '',
//   //     '',
//   //     '',
//   //     ''
//   //   ]);
//   //   rows.add([]);
//   //
//   //   rows.add([
//   //     'SL No.',
//   //     'UNIQUE ID',
//   //     'DESIGNATION',
//   //     'NAME',
//   //     'DATE',
//   //     'PRESENT',
//   //     'OT',
//   //     'CHECK-IN',
//   //     'CHECK-OUT',
//   //     'LOCATION AREA',
//   //     'LOCATION SIZE',
//   //     'PHOTO'
//   //   ]);
//   //
//   //   for (int i = 0; i < data.length; i++) {
//   //     final r = data[i];
//   //     final u = r['user'] ?? {};
//   //
//   //     // -------- LOCATION FIX (ALL CASES) --------
//   //     final location =
//   //         r['checkInLocation'] ??
//   //             r['location'] ??
//   //             {};
//   //
//   //     final lat =
//   //         location['latitude'] ??
//   //             location['lat'] ??
//   //             r['latitude'] ??
//   //             '';
//   //
//   //     final lng =
//   //         location['longitude'] ??
//   //             location['lng'] ??
//   //             r['longitude'] ??
//   //             '';
//   //
//   //     final address =
//   //         location['address'] ??
//   //             r['address'] ??
//   //             '';
//   //
//   //     // -------- STATUS FIX --------
//   //     String status = 'ABSENT';
//   //     final rawStatus = r['status']?.toString().toUpperCase() ?? '';
//   //
//   //     if (
//   //     rawStatus == 'P' ||
//   //         rawStatus == 'PRESENT' ||
//   //         rawStatus == 'PRESNT' ||
//   //         r['isPresent'] == true
//   //     ) {
//   //       status = 'PRESNT';
//   //     }
//   //
//   //     // -------- TIME FIX (ALL KEYS) --------
//   //     final checkInTime =
//   //         r['checkInTime'] ??
//   //             r['checkinTime'] ??
//   //             r['check_in_time'];
//   //
//   //     final checkOutTime =
//   //         r['checkOutTime'] ??
//   //             r['checkoutTime'] ??
//   //             r['check_out_time'];
//   //
//   //     rows.add([
//   //       i + 1,
//   //       u['userId'] ?? 'N/A',
//   //       (u['role'] ?? 'N/A').toString().toUpperCase(),
//   //       u['name'] ?? 'N/A',
//   //       _formatDate(r['date'] ?? r['dateTime']),
//   //       status,
//   //       r['ot'] ?? r['overtime'] ?? 0,
//   //       _formatTime(checkInTime),
//   //       _formatTime(checkOutTime),
//   //       address,
//   //       '$lng - $lat',
//   //       ''
//   //     ]);
//   //   }
//   //
//   //   return const ListToCsvConverter().convert(rows);
//   // }
//
//   // ============================================================
//   // API CALL
//   // ============================================================
//   // Future<void> _exportAttendanceReport({
//   //   required String endpoint,
//   //   required bool isMonthly,
//   //   required String prefix,
//   // }) async {
//   //   try {
//   //     final prefs = await SharedPreferences.getInstance();
//   //     final token = prefs.getString('token');
//   //     if (token == null) return _showError("Unauthorized");
//   //
//   //     final res = await http.get(
//   //       Uri.parse('$apiBaseUrl$endpoint'),
//   //       headers: {'Authorization': 'Bearer $token'},
//   //     );
//   //
//   //     if (res.statusCode != 200) {
//   //       return _showError("Server error ${res.statusCode}");
//   //     }
//   //
//   //     final data = jsonDecode(res.body)['data'] ?? [];
//   //     print("MONTHLY API SAMPLE => ${data.isNotEmpty ? data.first : 'EMPTY'}");//dedug
//   //     if (data.isEmpty) return _showError("No data found");
//   //
//   //     final csv = isMonthly
//   //         ? _generateMonthlyDetailedCSV(data)
//   //         : _generateDailyCSV(data);
//   //     final fileName =
//   //         "${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
//   //
//   //     await _saveCsvFile(csv, fileName);
//   //   } catch (e) {
//   //     _showError(e.toString());
//   //   }
//   // }
//
//
//   Future<void> _exportAttendanceReport({
//     required String endpoint,
//     required bool isMonthly,
//     required String prefix,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//
//       if (token == null) {
//         print("❌ TOKEN NOT FOUND");
//         return _showError("Unauthorized");
//       }
//
//       final url = '$apiBaseUrl$endpoint';
//
//       // 🔹 PRINT REQUEST DETAILS
//       print("🚀 REQUEST START =====================");
//       print("➡️ URL        => $url");
//       print("➡️ METHOD     => GET");
//       print("➡️ TOKEN      => Bearer $token");
//       print("➡️ HEADERS    => { Authorization: Bearer <token> }");
//       print("🚀 REQUEST END =======================");
//
//       final res = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       // 🔹 PRINT RESPONSE DETAILS
//       print("📥 RESPONSE START ====================");
//       print("✅ STATUS CODE => ${res.statusCode}");
//       print("📦 RAW BODY   => ${res.body}");
//       print("📥 RESPONSE END ======================");
//
//       if (res.statusCode != 200) {
//         return _showError("Server error ${res.statusCode}");
//       }
//
//       final decoded = jsonDecode(res.body);
//
//       // 🔹 PRINT DECODED JSON
//       print("🧩 DECODED JSON => $decoded");
//
//       final data = decoded['data'] ?? [];
//
//       print("📊 DATA COUNT => ${data.length}");
//       if (data.isNotEmpty) {
//         print("📄 FIRST RECORD => ${data.first}");
//       }
//
//       if (data.isEmpty) {
//         return _showError("No data found");
//       }
//
//       final csv = isMonthly
//           ? _generateMonthlyDetailedCSV(data)
//           : _generateDailyCSV(data);
//
//       final fileName =
//           "${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
//
//       print("📝 CSV FILE NAME => $fileName");
//
//       await _saveCsvFile(csv, fileName);
//     } catch (e) {
//       print("❌ EXPORT ERROR => $e");
//       _showError(e.toString());
//     }
//   }
//
//
//
//   // ============================================================
//   // DATE PICKERS
//   // ============================================================
//   Future<void> _pickDailyDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _dailyDate,
//       firstDate: DateTime(2023),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) setState(() => _dailyDate = picked);
//   }
//
//   Future<void> _pickMonthlyDate(bool isFrom) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2023),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isFrom) {
//           _monthlyFromDate = picked;
//           _monthlyToDate ??= picked;
//         } else {
//           _monthlyToDate = picked;
//         }
//       });
//     }
//   }
//
//   // ============================================================
//   // HELPERS
//
//   // ============================================================
// // HELPERS - FIXED FOR TIMEZONE
// // ============================================================
//
//   String _formatDate(dynamic d) {
//     if (d == null) return 'N/A';
//
//     try {
//       DateTime dateTime;
//
//       // Parse the date string
//       if (d is String) {
//         dateTime = DateTime.parse(d);
//       } else if (d is DateTime) {
//         dateTime = d;
//       } else {
//         return 'N/A';
//       }
//
//       // Convert UTC to local timezone (IST)
//       if (dateTime.isUtc) {
//         dateTime = dateTime.toLocal();
//       }
//
//       return DateFormat('dd-MM-yyyy').format(dateTime);
//     } catch (e) {
//       print("❌ Date format error: $e for value: $d");
//       return 'N/A';
//     }
//   }
//
//   String _formatTime(dynamic t) {
//     if (t == null) return '';
//
//     try {
//       DateTime dateTime;
//
//       // Parse the time string
//       if (t is String) {
//         dateTime = DateTime.parse(t);
//       } else if (t is DateTime) {
//         dateTime = t;
//       } else {
//         return '';
//       }
//
//       // Convert UTC to local timezone (IST)
//       if (dateTime.isUtc) {
//         dateTime = dateTime.toLocal();
//       }
//
//       return DateFormat('hh:mm a').format(dateTime);
//     } catch (e) {
//       print("❌ Time format error: $e for value: $t");
//       return '';
//     }
//   }
//
//   String _getPresentStatus(Map r) {
//     if (r['status'] != null) return r['status'];
//     if (r['isPresent'] == true) return 'Present';
//     return 'Absent';
//   }
//
//   String _formatLocation(Map r) {
//     final lat = r['latitude'] ?? r['location']?['latitude'];
//     final lng = r['longitude'] ?? r['location']?['longitude'];
//     return (lat != null && lng != null) ? "$lat - $lng" : 'N/A';
//   }
//
//   void _showError(String m) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(m), backgroundColor: Colors.red)
//     );
//   }
//
//
//
//   // // ============================================================
//   // String _formatDate(d) {
//   //   try {
//   //     return DateFormat('dd-MM-yyyy').format(DateTime.parse(d));
//   //   } catch (_) {
//   //     return 'N/A';
//   //   }
//   // }
//   //
//   // String _formatTime(t) {
//   //   try {
//   //     return DateFormat('hh:mm a').format(DateTime.parse(t));
//   //   } catch (_) {
//   //     return '';
//   //   }
//   // }
//   //
//   // String _getPresentStatus(Map r) {
//   //   if (r['status'] != null) return r['status'];
//   //   if (r['isPresent'] == true) return 'Present';
//   //   return 'Absent';
//   // }
//   //
//   // String _formatLocation(Map r) {
//   //   final lat = r['latitude'] ?? r['location']?['latitude'];
//   //   final lng = r['longitude'] ?? r['location']?['longitude'];
//   //   return (lat != null && lng != null) ? "$lat - $lng" : 'N/A';
//   // }
//
//   // void _showError(String m) {
//   //   if (!mounted) return;
//   //   ScaffoldMessenger.of(context)
//   //       .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: primaryBlue,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
//           ),
//         ),
//         title: const Text("Reports",
//             style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _reportCard(
//               title: "Daily Attendance Report",
//               description:
//               "Download detailed daily attendance with check-in and check-out time.",
//               icon: LucideIcons.calendarDays,
//               extra: OutlinedButton.icon(
//                 onPressed: _pickDailyDate,
//                 icon: const Icon(Icons.calendar_today),
//                 label:
//                 Text(DateFormat('dd-MM-yyyy').format(_dailyDate)),
//               ),
//               isLoading: _isDailyExporting,
//               onDownload: () {
//                 final d =
//                 DateFormat('yyyy-MM-dd').format(_dailyDate);
//                 _exportAttendanceReport(
//                   endpoint:
//                   "/api/v1/reports/attendance/daily?startDate=$d&endDate=$d",
//                   isMonthly: false,
//                   prefix: "daily_attendance",
//                 );
//               },
//             ),
//             _reportCard(
//               title: "Monthly Attendance Report",
//               description:
//               "Monthly summary grouped by Management, Supervisor and Workers.",
//               icon: LucideIcons.calendarRange,
//               extra: Row(
//                 children: [
//                   _dateBtn(
//                       "From", _monthlyFromDate, () => _pickMonthlyDate(true)),
//                   const SizedBox(width: 8),
//                   _dateBtn(
//                       "To", _monthlyToDate, () => _pickMonthlyDate(false)),
//                 ],
//               ),
//               isLoading: _isMonthlyExporting,
//               onDownload: () {
//                 if (_monthlyFromDate == null ||
//                     _monthlyToDate == null) {
//                   _showError("Select date range");
//                   return;
//                 }
//                 final f = DateFormat('yyyy-MM-dd')
//                     .format(_monthlyFromDate!);
//                 final t = DateFormat('yyyy-MM-dd')
//                     .format(_monthlyToDate!);
//                 _exportAttendanceReport(
//                   endpoint:
//                   "/api/v1/reports/attendance/monthly?startDate=$f&endDate=$t",
//                   isMonthly: true,
//                   prefix: "monthly_attendance",
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _reportCard({
//     required String title,
//     required String description,
//     required IconData icon,
//     required Widget extra,
//     required bool isLoading,
//     required VoidCallback onDownload,
//   }) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(children: [
//               CircleAvatar(
//                 backgroundColor: lightBlue,
//                 child: Icon(icon, color: primaryBlue),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(title,
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: primaryBlue)),
//               ),
//             ]),
//             const SizedBox(height: 8),
//             Text(description,
//                 style:
//                 const TextStyle(fontSize: 13, color: Colors.black54)),
//             const SizedBox(height: 12),
//             extra,
//             const SizedBox(height: 12),
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton.icon(
//                 onPressed: isLoading ? null : onDownload,
//                 icon: isLoading
//                     ? const SizedBox(
//                     width: 18,
//                     height: 18,
//                     child: CircularProgressIndicator(
//                         strokeWidth: 2, color: Colors.white))
//                     : const Icon(Icons.download, color: Colors.white),
//                 label: const Text("Download",
//                     style: TextStyle(color: Colors.white)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryBlue,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10)),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _dateBtn(String label, DateTime? date, VoidCallback onTap) {
//     return OutlinedButton(
//       onPressed: onTap,
//       child: Text(
//         date == null
//             ? label
//             : DateFormat('dd-MM-yyyy').format(date),
//       ),
//     );
//   }
// }