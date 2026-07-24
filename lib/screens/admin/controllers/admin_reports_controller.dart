// lib/screens/admin/controllers/admin_reports_controller.dart

import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/file_saver_mobile.dart'
if (dart.library.html) 'package:smartcare_app/utils/file_saver_web.dart';

import 'package:smartcare_app/utils/constants.dart';

class AdminReportsController extends GetxController {
  final isDailyExporting   = false.obs;
  final isMonthlyExporting = false.obs;
  final dailyDate          = DateTime.now().obs;
  final monthlyFrom        = Rxn<DateTime>();
  final monthlyTo          = Rxn<DateTime>();

  int _holidaysCount = 0;

  // ── Debug Logger ───────────────────────────────────────────────────────
  void _log(String tag, dynamic msg) {
    debugPrint('╔══ [AdminReports][$tag] ══════════════════════════════');
    debugPrint('║  $msg');
    debugPrint('╚══════════════════════════════════════════════════════');
  }

  void _logSection(String tag, Map<String, dynamic> sections) {
    debugPrint('╔══ [AdminReports][$tag] ══════════════════════════════');
    sections.forEach((key, value) {
      debugPrint('║  [$key]: $value');
    });
    debugPrint('╚══════════════════════════════════════════════════════');
  }

  // ── Date Pickers ───────────────────────────────────────────────────────
  Future<void> pickDailyDate(BuildContext ctx) async {
    final p = await showDatePicker(
        context: ctx,
        initialDate: dailyDate.value,
        firstDate: DateTime(2023),
        lastDate: DateTime.now());
    if (p != null) {
      dailyDate.value = p;
      _log('pickDailyDate', 'Selected daily date: ${DateFormat('yyyy-MM-dd').format(p)}');
    }
  }

  Future<void> pickMonthlyDate(BuildContext ctx, bool isFrom) async {
    final p = await showDatePicker(
        context: ctx,
        initialDate: DateTime.now(),
        firstDate: DateTime(2023),
        lastDate: DateTime.now());
    if (p != null) {
      if (isFrom) {
        monthlyFrom.value = p;
        monthlyTo.value ??= p;
      } else {
        monthlyTo.value = p;
      }
      _log('pickMonthlyDate', '${isFrom ? "FROM" : "TO"} date selected: ${DateFormat('yyyy-MM-dd').format(p)}');
      _log('pickMonthlyDate',
          'Current range → FROM: ${monthlyFrom.value != null ? DateFormat('yyyy-MM-dd').format(monthlyFrom.value!) : "null"}'
              '  |  TO: ${monthlyTo.value != null ? DateFormat('yyyy-MM-dd').format(monthlyTo.value!) : "null"}');
    }
  }

  // ── Export ─────────────────────────────────────────────────────────────
  Future<void> exportDaily() async {
    isDailyExporting.value = true;
    final d = DateFormat('yyyy-MM-dd').format(dailyDate.value);
    _log('exportDaily', 'Starting daily export for date: $d');
    await _export(
        endpoint: '/api/v1/reports/attendance/daily?startDate=$d&endDate=$d',
        isMonthly: false,
        prefix: 'daily_attendance');
    isDailyExporting.value = false;
  }

  Future<void> exportMonthly() async {
    if (monthlyFrom.value == null || monthlyTo.value == null) {
      _err('Select date range');
      return;
    }
    isMonthlyExporting.value = true;
    final f = DateFormat('yyyy-MM-dd').format(monthlyFrom.value!);
    final t = DateFormat('yyyy-MM-dd').format(monthlyTo.value!);

    _log('exportMonthly', 'Starting monthly export — FROM: $f  |  TO: $t');

    await _export(
        endpoint:
        '/api/v1/reports/attendance/monthly?startDate=$f&endDate=$t',
        isMonthly: true,
        prefix: 'monthly_attendance');
    isMonthlyExporting.value = false;
  }

  Future<void> _export({
    required String endpoint,
    required bool isMonthly,
    required String prefix,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // ── 1. Token check ──
      _log('_export', 'FULL TOKEN: $token');

      // ── 2. Full Request URL ──
      final fullUrl = '$apiBaseUrl$endpoint';


      final res = await http.get(Uri.parse(fullUrl),
          headers: {'Authorization': 'Bearer $token'});

      // ── 3. Raw Response ──
      _logSection('RESPONSE', {
        'Status Code' : res.statusCode,
        'Headers'     : res.headers,
        'Body (raw)'  : res.body.length > 2000
            ? '${res.body.substring(0, 2000)}... [TRUNCATED, total ${res.body.length} chars]'
            : res.body,
      });

      if (res.statusCode != 200) { _err('Server error ${res.statusCode}'); return; }

      // ── 4. Decoded JSON ──
      final decoded = jsonDecode(res.body);
      _logSection('DECODED JSON', {
        'Keys in response' : decoded.keys.toList(),
        'holidaysCount'    : decoded['holidaysCount'],
        'data length'      : (decoded['data'] as List?)?.length ?? 'null',
      });

      final data = decoded['data'] ?? [];
      if (isMonthly) _holidaysCount = decoded['holidaysCount'] ?? 0;

      if (data.isEmpty) {
        _log('_export', 'DATA IS EMPTY — no records returned from API');
        _err('No data found');
        return;
      }

      // ── 5. First record preview ──
      _log('_export', 'First record sample:\n${const JsonEncoder.withIndent('  ').convert(data[0])}');

      // ── 6. Build CSV ──
      final csv = isMonthly ? _monthlyCSV(data) : _dailyCSV(data);

      // ── 7. CSV Preview ──
      final csvLines = csv.split('\n');
      _logSection('CSV BUILT', {
        'Total lines'   : csvLines.length,
        'Total chars'   : csv.length,
        'Header row'    : csvLines.isNotEmpty ? csvLines[0] : 'N/A',
        'First data row': csvLines.length > 5 ? csvLines[5] : 'N/A',
        'Last data row' : csvLines.isNotEmpty ? csvLines[csvLines.length - 1] : 'N/A',
      });

      final fileName = '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      _log('_export', 'Saving file as: $fileName');

      await _save(csv, fileName);

    } catch (e, stackTrace) {
      _logSection('ERROR', {
        'Exception'  : e.toString(),
        'StackTrace' : stackTrace.toString().substring(0, stackTrace.toString().length > 500 ? 500 : stackTrace.toString().length),
      });
      _err(e.toString());
    }
  }

  // ── CSV Builders ───────────────────────────────────────────────────────
  String _dailyCSV(List data) {
    data.sort((a, b) =>
        _priority(a['user']?['role']).compareTo(_priority(b['user']?['role'])));

    final rows  = <List<dynamic>>[];
    final month = DateFormat('MMMM').format(dailyDate.value).toUpperCase();
    final days  = DateTime(dailyDate.value.year, dailyDate.value.month + 1, 0).day;

    rows.add([]);
    rows.add(['', '{$month $days DAYS} THIS IS DAILY REPORT', '', '', '', '', '', '', '', '', '', '']);
    rows.add([]);
    rows.add(['SL No.', 'UNIQUE ID', 'DESIGNATION', 'NAME', 'DATE', 'PRESENT',
      'OT', 'CHECK-IN', 'CHECK-OUT', 'LOCATION AREA', 'LOCATION SIZE', 'PHOTO']);

    for (int i = 0; i < data.length; i++) {
      final r   = data[i];
      final u   = r['user']          ?? {};
      final loc = r['checkInLocation'] ?? {};
      final lng = loc['longitude']   ?? r['longitude'] ?? '0.0';
      final lat = loc['latitude']    ?? r['latitude']  ?? '0.0';
      String status = 'ABSENT';
      if (r['status'] != null) {
        final s = r['status'].toString().toUpperCase();
        status  = (s.contains('PRESENT') || s == 'PRESNT') ? 'PRESNT' : 'ABSENT';
      }
      rows.add([
        i + 1, u['userId'] ?? 'N/A',
        (u['role'] ?? 'N/A').toString().toUpperCase(),
        u['name'] ?? 'N/A',
        r['dateDisplay'] ?? _fmtDate(r['date'] ?? r['dateTime']),
        status,
        r['ot'] ?? r['overtime'] ?? 0,
        r['checkInTimeDisplay']  ?? _fmtTime(r['checkInTime']  ?? r['checkinTime']),
        r['checkOutTimeDisplay'] ?? _fmtTime(r['checkOutTime'] ?? r['checkoutTime']),
        loc['address'] ?? r['address'] ?? '',
        '$lng - $lat',
        '',
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  String _monthlyCSV(List data) {
    data.sort((a, b) =>
        _priority(a['user']?['role']).compareTo(_priority(b['user']?['role'])));

    final rows  = <List<dynamic>>[];
    String range = '';
    if (monthlyFrom.value != null && monthlyTo.value != null) {
      range =
      '${DateFormat('dd-MM-yyyy').format(monthlyFrom.value!)} TO ${DateFormat('dd-MM-yyyy').format(monthlyTo.value!)}';
    }

    // ── Debug: log each record going into monthly CSV ──
    _log('_monthlyCSV', 'Building CSV for ${data.length} records | range: $range | holidays: $_holidaysCount');
    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final u = r['user'] ?? {};
      _log('_monthlyCSV → row ${i + 1}',
          'userId=${u['userId']} | name=${u['name']} | role=${u['role']} | '
              'present=${r['presentDays']} | absent=${r['absentDays']} | '
              'leave=${r['leaveDays']} | late=${r['lateDays']} | ot=${r['overtimeHours'] ?? r['overtime'] ?? r['ot']}');
    }

    rows.add([]);
    rows.add(['', 'MONTHLY ATTENDANCE SUMMARY REPORT ($range)', '', '', '', '', '', '', '', '']);
    rows.add(['', 'Total Holidays in Period: $_holidaysCount', '', '', '', '', '', '', '', '']);
    rows.add([]);
    rows.add(['SL No.', 'UNIQUE ID', 'DESIGNATION', 'NAME', 'PRESENT DAYS',
      'ABSENT DAYS', 'LEAVE DAYS', 'HOLIDAYS', 'LATE DAYS', 'TOTAL OT HOURS']);

    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final u = r['user'] ?? {};
      rows.add([
        i + 1, u['userId'] ?? 'N/A',
        (u['role'] ?? 'N/A').toString().toUpperCase(),
        u['name']              ?? 'N/A',
        r['presentDays']       ?? 0,
        r['absentDays']        ?? 0,
        r['leaveDays']         ?? 0,
        _holidaysCount,
        r['lateDays']          ?? 0,
        r['overtimeHours'] ?? r['overtime'] ?? r['ot'] ?? 0,
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  int _priority(String? r) {
    r = r?.toUpperCase() ?? '';
    if (r.contains('MANAGEMENT')) return 1;
    if (r.contains('SUPERVISOR')) return 2;
    return 3;
  }

  String _fmtDate(dynamic d) {
    if (d == null) return 'N/A';
    try {
      DateTime dt = d is String ? DateTime.parse(d) : d as DateTime;
      if (dt.isUtc) dt = dt.toLocal();
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) { return 'N/A'; }
  }

  String _fmtTime(dynamic t) {
    if (t == null) return '';
    try {
      DateTime dt = t is String ? DateTime.parse(t) : t as DateTime;
      if (dt.isUtc) dt = dt.toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) { return ''; }
  }

  Future<void> _save(String csv, String name) async {
    try {
      if (kIsWeb) {
        _log('_save', 'Platform: WEB — using saveCsvWeb()');
        saveCsvWeb(csv, name);
        _ok('Report downloaded successfully');
        return;
      }
      _log('_save', 'Platform: MOBILE — invoking downloads_channel');
      const ch = MethodChannel('downloads_channel');
      final res = await ch.invokeMethod('saveToDownloads', {
        'fileName': name,
        'bytes': utf8.encode(csv),
        'mime': lookupMimeType(name) ?? 'text/csv',
      });
      _log('_save', 'MethodChannel result: $res');
      if (res == null) { _err('Download failed'); return; }
      _ok('Report saved in Downloads folder');
    } catch (e) {
      _log('_save ERROR', 'Exception during save: $e');
      _err('Download error: $e');
    }
  }

  void _ok(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.green, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));

  void _err(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.red, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
}