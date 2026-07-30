// lib/screens/admin/controllers/admin_reports_controller.dart

import 'dart:convert';
// `excel`'s Border type would otherwise collide with Flutter's Border.
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/file_saver_mobile.dart'
if (dart.library.html) 'package:smartcare_app/utils/file_saver_web.dart';

import 'package:smartcare_app/utils/constants.dart';

// ── Report styling palette ────────────────────────────────────────────────
// One place for every color/style the workbooks use, so the daily and
// monthly sheets stay visually consistent.
class _ReportStyles {
  static final title = CellStyle(
    bold: true,
    fontSize: 14,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('FF0D47A1'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final subtitle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('FF0D47A1'),
    backgroundColorHex: ExcelColor.fromHexString('FFE3F2FD'),
    horizontalAlign: HorizontalAlign.Left,
  );

  static final header = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('FF0D47A1'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final subHeader = CellStyle(
    bold: true,
    italic: true,
    fontSize: 9,
    fontColorHex: ExcelColor.fromHexString('FF455A64'),
    backgroundColorHex: ExcelColor.fromHexString('FFECEFF1'),
    horizontalAlign: HorizontalAlign.Center,
  );

  static final identityCell = CellStyle(horizontalAlign: HorizontalAlign.Left);

  static final identityCellAlt = CellStyle(
    horizontalAlign: HorizontalAlign.Left,
    backgroundColorHex: ExcelColor.fromHexString('FFF7F9FC'),
  );

  static final totalsCell = CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    backgroundColorHex: ExcelColor.fromHexString('FFEFF3F8'),
  );

  static final present = CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    fontColorHex: ExcelColor.fromHexString('FF1B5E20'),
    backgroundColorHex: ExcelColor.fromHexString('FFC8E6C9'),
  );

  static final absent = CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    fontColorHex: ExcelColor.fromHexString('FFB71C1C'),
    backgroundColorHex: ExcelColor.fromHexString('FFFFCDD2'),
  );

  static final leave = CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    fontColorHex: ExcelColor.fromHexString('FFE65100'),
    backgroundColorHex: ExcelColor.fromHexString('FFFFE0B2'),
  );

  static final weekOff = CellStyle(
    horizontalAlign: HorizontalAlign.Center,
    fontColorHex: ExcelColor.fromHexString('FF455A64'),
    backgroundColorHex: ExcelColor.fromHexString('FFECEFF1'),
  );

  static final holiday = CellStyle(
    horizontalAlign: HorizontalAlign.Center,
    fontColorHex: ExcelColor.fromHexString('FF6A1B9A'),
    backgroundColorHex: ExcelColor.fromHexString('FFE1BEE7'),
  );

  // Sunday worked - same green as present, but flagged with a bolder border
  // color isn't supported without the hidden Border type, so a distinct
  // teal tone is used instead to make it visually stand out from a normal
  // present day.
  static final sundayWorked = CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    fontColorHex: ExcelColor.fromHexString('FF004D40'),
    backgroundColorHex: ExcelColor.fromHexString('FFB2DFDB'),
  );

  static final legendLabel = CellStyle(
    bold: true,
    fontSize: 9,
    fontColorHex: ExcelColor.fromHexString('FF616161'),
  );
}

class AdminReportsController extends GetxController {
  final isDailyExporting   = false.obs;
  final isMonthlyExporting = false.obs;
  final dailyDate          = DateTime.now().obs;
  final monthlyMonth       = DateTime.now().month.obs;
  final monthlyYear        = DateTime.now().year.obs;

  int _holidaysCount = 0;

  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<int> get selectableYears {
    final current = DateTime.now().year;
    return [for (int y = current - 3; y <= current; y++) y];
  }

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

  void setMonth(int month) {
    monthlyMonth.value = month;
    _log('setMonth', 'Month selected: $month (${monthNames[month - 1]})');
  }

  void setYear(int year) {
    monthlyYear.value = year;
    _log('setYear', 'Year selected: $year');
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
    isMonthlyExporting.value = true;
    final m = monthlyMonth.value;
    final y = monthlyYear.value;

    _log('exportMonthly', 'Starting monthly export — $m/$y');

    await _export(
        endpoint: '/api/v1/reports/attendance/month-matrix?month=$m&year=$y',
        isMonthly: true,
        prefix: 'monthly_attendance_${monthNames[m - 1]}_$y');
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

      // ── 6. Build styled workbook ──
      final bytes = isMonthly ? _monthMatrixExcel(decoded) : _dailyExcel(data);
      _log('_export', 'Workbook built: ${bytes.length} bytes');

      final fileName = '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      _log('_export', 'Saving file as: $fileName');

      await _save(bytes, fileName);

    } catch (e, stackTrace) {
      _logSection('ERROR', {
        'Exception'  : e.toString(),
        'StackTrace' : stackTrace.toString().substring(0, stackTrace.toString().length > 500 ? 500 : stackTrace.toString().length),
      });
      _err(e.toString());
    }
  }

  // ── Workbook Builders ──────────────────────────────────────────────────
  static const _dailyColumnCount = 12;

  // Trailing summary columns on the month grid:
  // Present, Absent, Sunday Worked, OT, Working Days.
  static const _monthSummaryCols = 5;

  List<int> _dailyExcel(List data) {
    data.sort((a, b) =>
        _priority(a['user']?['role']).compareTo(_priority(b['user']?['role'])));

    final workbook = Excel.createExcel();
    final defaultName = workbook.getDefaultSheet()!;
    workbook.rename(defaultName, 'Daily Attendance');
    final sheet = workbook['Daily Attendance'];

    final month = DateFormat('MMMM').format(dailyDate.value).toUpperCase();
    final dateLabel = DateFormat('dd MMM yyyy').format(dailyDate.value);
    const lastCol = _dailyColumnCount - 1;

    // Title row
    sheet.appendRow(['DAILY ATTENDANCE REPORT — $month, $dateLabel']
        .map<CellValue?>(TextCellValue.new)
        .toList()
      ..addAll(List.filled(lastCol, null)));
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: 0));
    _styleRow(sheet, 0, 0, lastCol, _ReportStyles.title);
    sheet.setRowHeight(0, 24);

    // Header row
    const headers = [
      'Sr.', 'Emp ID', 'Designation', 'Name', 'Date', 'Day', 'Status',
      'Sunday Work', 'OT (hrs)', 'Check-In', 'Check-Out', 'Location',
    ];
    sheet.appendRow(headers.map<CellValue?>(TextCellValue.new).toList());
    _styleRow(sheet, 1, 0, lastCol, _ReportStyles.header);
    sheet.setRowHeight(1, 20);

    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final u = r['user'] ?? {};
      final loc = r['checkInLocation'] ?? {};
      final lng = loc['longitude'] ?? r['longitude'];
      final lat = loc['latitude'] ?? r['latitude'];
      final recordDate = r['date'] ?? r['dateTime'];
      final address = (loc['address'] ?? r['address'] ?? '').toString();
      final coords = (lng != null && lat != null) ? '$lat, $lng' : '';
      final location =
          [address, coords].where((s) => s.isNotEmpty).join(' — ');

      final isPresent = ['present', 'late']
          .contains((r['status'] ?? '').toString().toLowerCase());
      final sundayWorked = r['sundayWorked'] == true;

      final rowIndex = sheet.maxRows;
      sheet.appendRow(<CellValue?>[
        IntCellValue(i + 1),
        TextCellValue(u['userId'] ?? 'N/A'),
        TextCellValue((u['role'] ?? 'N/A').toString().toUpperCase()),
        TextCellValue(u['name'] ?? 'N/A'),
        TextCellValue(r['dateDisplay'] ?? _fmtDate(recordDate)),
        TextCellValue(r['dayName'] ?? _dayName(recordDate)),
        TextCellValue(isPresent ? 'PRESENT' : 'ABSENT'),
        TextCellValue(sundayWorked ? 'YES' : ''),
        DoubleCellValue(
            ((r['ot'] ?? r['overtime'] ?? 0) as num).toDouble()),
        TextCellValue(r['checkInTimeDisplay'] ??
            _fmtTime(r['checkInTime'] ?? r['checkinTime'])),
        TextCellValue(r['checkOutTimeDisplay'] ??
            _fmtTime(r['checkOutTime'] ?? r['checkoutTime'])),
        TextCellValue(location),
      ]);

      final banded = i.isOdd ? _ReportStyles.identityCellAlt : null;
      _styleRow(sheet, rowIndex, 0, lastCol, banded);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .cellStyle = isPresent ? _ReportStyles.present : _ReportStyles.absent;
      if (sundayWorked) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 7, rowIndex: rowIndex))
            .cellStyle = _ReportStyles.sundayWorked;
      }
    }

    _setDailyColumnWidths(sheet);
    return workbook.encode()!;
  }

  void _setDailyColumnWidths(Sheet sheet) {
    const widths = <int, double>{
      0: 6, 1: 14, 2: 14, 3: 20, 4: 12, 5: 11,
      6: 11, 7: 12, 8: 10, 9: 11, 10: 11, 11: 30,
    };
    widths.forEach(sheet.setColumnWidth);
  }

  // Month grid: one row per employee, one column per day of the month,
  // matching the layout the office already uses in its attendance sheet.
  // Cell codes: P = present, A = absent, L = leave, WO = week off (Sunday),
  // H = holiday.
  List<int> _monthMatrixExcel(Map<String, dynamic> decoded) {
    final List days = decoded['days'] ?? [];
    final List data = decoded['data'] ?? [];
    final int month = decoded['month'] ?? monthlyMonth.value;
    final int year = decoded['year'] ?? monthlyYear.value;
    final int workingDays = decoded['workingDays'] ?? 0;
    final monthName = monthNames[month - 1].toUpperCase();

    _log('_monthMatrixExcel',
        'Building grid for ${data.length} employees | $monthName $year | '
        '${days.length} days | workingDays=$workingDays | holidays=$_holidaysCount');

    final workbook = Excel.createExcel();
    final defaultName = workbook.getDefaultSheet()!;
    workbook.rename(defaultName, 'Monthly Attendance');
    final sheet = workbook['Monthly Attendance'];

    const identityCols = 4; // Sr, Emp ID, Name, Designation
    const summaryCols = _monthSummaryCols;
    final lastCol = identityCols + days.length + summaryCols - 1;

    // Title row
    sheet.appendRow(['MONTHLY ATTENDANCE SUMMARY — $monthName $year']
        .map<CellValue?>(TextCellValue.new)
        .toList()
      ..addAll(List.filled(lastCol, null)));
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: 0));
    _styleRow(sheet, 0, 0, lastCol, _ReportStyles.title);
    sheet.setRowHeight(0, 24);

    // Info row
    sheet.appendRow(
        ['Working Days: $workingDays   |   Holidays: $_holidaysCount']
            .map<CellValue?>(TextCellValue.new)
            .toList()
          ..addAll(List.filled(lastCol, null)));
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: 1));
    _styleRow(sheet, 1, 0, lastCol, _ReportStyles.subtitle);

    // Header row: identity + day numbers + summary labels
    final headerRow = <CellValue?>[
      TextCellValue('Sr.'), TextCellValue('Emp ID'),
      TextCellValue('Name'), TextCellValue('Designation'),
      for (final d in days) IntCellValue(d['day'] as int),
      TextCellValue('Present'), TextCellValue('Absent'),
      TextCellValue('Sunday\nWorked'), TextCellValue('OT\n(hrs)'),
      TextCellValue('Working\nDays'),
    ];
    sheet.appendRow(headerRow);
    final headerRowIndex = sheet.maxRows - 1;
    _styleRow(sheet, headerRowIndex, 0, lastCol, _ReportStyles.header);
    sheet.setRowHeight(headerRowIndex, 28);

    // Sub-header row: weekday abbreviation under each day number
    final subHeaderRow = <CellValue?>[
      null, null, null, null,
      for (final d in days) TextCellValue((d['dayShort'] ?? '') as String),
      null, null, null, null, null, null, null,
    ];
    sheet.appendRow(subHeaderRow);
    final subHeaderRowIndex = sheet.maxRows - 1;
    _styleRow(
        sheet, subHeaderRowIndex, identityCols, identityCols + days.length - 1,
        _ReportStyles.subHeader);

    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final u = r['user'] ?? {};
      final List cells = r['cells'] ?? [];

      sheet.appendRow(<CellValue?>[
        IntCellValue(i + 1),
        TextCellValue(u['userId'] ?? 'N/A'),
        TextCellValue(u['name'] ?? 'N/A'),
        TextCellValue(
            (u['designation'] ?? u['role'] ?? 'N/A').toString().toUpperCase()),
        for (final c in cells) TextCellValue(c as String),
        IntCellValue((r['totalPresent'] ?? 0) as int),
        IntCellValue((r['totalAbsent'] ?? 0) as int),
        IntCellValue((r['sundayWorkedDays'] ?? 0) as int),
        IntCellValue((r['overtimeHours'] ?? 0) as int),
        IntCellValue((r['workingDays'] ?? workingDays) as int),
      ]);
      final rowIndex = sheet.maxRows - 1;

      final identityStyle =
          i.isOdd ? _ReportStyles.identityCellAlt : _ReportStyles.identityCell;
      for (int col = 0; col < identityCols; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
            .cellStyle = identityStyle;
      }

      for (int d = 0; d < cells.length; d++) {
        final col = identityCols + d;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
            .cellStyle = _cellStyleFor(cells[d] as String);
      }

      for (int col = identityCols + days.length; col <= lastCol; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
            .cellStyle = _ReportStyles.totalsCell;
      }
    }

    _setMonthMatrixColumnWidths(sheet, days.length, identityCols);
    _appendLegend(sheet, lastCol);

    return workbook.encode()!;
  }

  CellStyle _cellStyleFor(String code) {
    switch (code) {
      case 'P':
        return _ReportStyles.present;
      case 'A':
        return _ReportStyles.absent;
      case 'L':
        return _ReportStyles.leave;
      case 'H':
        return _ReportStyles.holiday;
      case 'WO':
      default:
        return _ReportStyles.weekOff;
    }
  }

  void _setMonthMatrixColumnWidths(
      Sheet sheet, int dayCount, int identityCols) {
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 13);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 15);
    for (int d = 0; d < dayCount; d++) {
      sheet.setColumnWidth(identityCols + d, 4);
    }
    final summaryStart = identityCols + dayCount;
    for (int col = summaryStart;
        col < summaryStart + _monthSummaryCols;
        col++) {
      sheet.setColumnWidth(col, 10);
    }
  }

  void _appendLegend(Sheet sheet, int lastCol) {
    sheet.appendRow(List.filled(lastCol + 1, null));

    final legendItems = <(String, String, CellStyle)>[
      ('P', 'Present', _ReportStyles.present),
      ('A', 'Absent', _ReportStyles.absent),
      ('L', 'Leave', _ReportStyles.leave),
      ('WO', 'Week Off', _ReportStyles.weekOff),
      ('H', 'Holiday', _ReportStyles.holiday),
    ];

    sheet.appendRow(<CellValue?>[
      TextCellValue('Legend:'),
      ...List.filled(lastCol, null),
    ]);
    final labelRow = sheet.maxRows - 1;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: labelRow))
        .cellStyle = _ReportStyles.legendLabel;

    for (final (code, meaning, style) in legendItems) {
      sheet.appendRow(<CellValue?>[
        TextCellValue(code),
        TextCellValue(meaning),
        ...List.filled(lastCol - 1, null),
      ]);
      final row = sheet.maxRows - 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .cellStyle = style;
    }
  }

  void _styleRow(
      Sheet sheet, int rowIndex, int startCol, int endCol, CellStyle? style) {
    if (style == null) return;
    for (int col = startCol; col <= endCol; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
          .cellStyle = style;
    }
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

  String _dayName(dynamic d) {
    if (d == null) return '';
    try {
      DateTime dt = d is String ? DateTime.parse(d) : d as DateTime;
      return DateFormat('EEEE').format(dt).toUpperCase();
    } catch (_) { return ''; }
  }

  String _fmtTime(dynamic t) {
    if (t == null) return '';
    try {
      DateTime dt = t is String ? DateTime.parse(t) : t as DateTime;
      if (dt.isUtc) dt = dt.toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) { return ''; }
  }

  static const _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  Future<void> _save(List<int> bytes, String name) async {
    try {
      if (kIsWeb) {
        _log('_save', 'Platform: WEB — using saveBytesWeb()');
        saveBytesWeb(bytes, name, _xlsxMime);
        _ok('Report downloaded successfully');
        return;
      }
      _log('_save', 'Platform: MOBILE — invoking downloads_channel');
      const ch = MethodChannel('downloads_channel');
      // MethodChannel's standard codec only marshals a Uint8List through to
      // Android's ByteArray - a plain List<int> (which is what
      // Excel.encode() returns) arrives as null on the Kotlin side.
      final res = await ch.invokeMethod('saveToDownloads', {
        'fileName': name,
        'bytes': Uint8List.fromList(bytes),
        'mime': _xlsxMime,
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