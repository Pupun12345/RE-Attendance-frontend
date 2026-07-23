// lib/screens/admin/controllers/admin_holiday_setup_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/utils/constants.dart';

// ─── Model ─────────────────────────────────────────────────────────────────

class Holiday {
  final String id;
  final String name;
  final DateTime date;
  final String type;

  Holiday(
      {required this.id,
      required this.name,
      required this.date,
      required this.type});

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
        id: json['_id'],
        name: json['name'],
        date: DateTime.parse(json['date']),
        type: json['type'] ?? 'company',
      );

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
}

// ─── Controller ────────────────────────────────────────────────────────────

class AdminHolidaySetupController extends GetxController {
  final holidays = <Holiday>[].obs;
  final isLoading = true.obs;
  final showForm = false.obs;
  final selectedDate = Rxn<DateTime>();
  final selectedType = 'company'.obs;
  final nameCtrl = TextEditingController();

  String? _token;

  @override
  void onInit() {
    super.onInit();
    _fetchHolidays();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    super.onClose();
  }

  Future<void> _fetchHolidays() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _err('Not authorized.');
        return;
      }
      final res = await http.get(Uri.parse('$apiBaseUrl/api/v1/holidays'),
          headers: {'Authorization': 'Bearer $_token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        holidays.value = (data['holidays'] as List)
            .map((h) => Holiday.fromJson(h))
            .toList();
      } else {
        _err('Failed to load holidays.');
      }
    } catch (e) {
      _err('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1), onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) selectedDate.value = picked;
  }

  void toggleForm() => showForm.value = !showForm.value;

  Future<void> saveHoliday() async {
    if (nameCtrl.text.trim().isEmpty || selectedDate.value == null) {
      _err('Please enter holiday name and select a date.');
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/holidays'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'name': nameCtrl.text.trim(),
          'date': selectedDate.value!.toIso8601String(),
          'type': selectedType.value,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['success'] == true) {
        nameCtrl.clear();
        selectedDate.value = null;
        showForm.value = false;
        _ok('Holiday added successfully!');
        _fetchHolidays();
      } else {
        _err(data['message'] ?? 'Failed to save holiday.');
      }
    } catch (e) {
      _err('Error: $e');
    }
  }

  Future<void> deleteHoliday(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$apiBaseUrl/api/v1/holidays/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _ok('Holiday deleted successfully!');
        _fetchHolidays();
      } else {
        _err(data['message'] ?? 'Failed to delete.');
      }
    } catch (e) {
      _err('Error: $e');
    }
  }

  void _ok(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12));

  void _err(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12));
}
