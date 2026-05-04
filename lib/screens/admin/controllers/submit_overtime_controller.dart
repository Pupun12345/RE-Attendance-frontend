// lib/screens/admin/controllers/submit_overtime_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

class SubmitOvertimeController extends GetxController {
  final formKey        = GlobalKey<FormState>();
  final hoursCtrl      = TextEditingController();
  final reasonCtrl     = TextEditingController();
  final selectedDate   = DateTime.now().obs;
  final isSubmitting   = false.obs;

  @override
  void onClose() {
    hoursCtrl.dispose();
    reasonCtrl.dispose();
    super.onClose();
  }

  String get formattedDate =>
      DateFormat('MMM dd, yyyy').format(selectedDate.value);

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
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

  Future<void> submitOvertime() async {
    if (!formKey.currentState!.validate()) return;

    isSubmitting.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _err('Authentication error. Please log in again.');
        return;
      }

      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/overtime'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date':   selectedDate.value.toIso8601String(),
          'hours':  double.tryParse(hoursCtrl.text) ?? 0,
          'reason': reasonCtrl.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['success'] == true) {
        Get.snackbar('', 'Overtime request submitted successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(12));
        Get.back();
      } else {
        _err(data['message'] ?? 'Failed to submit request.');
      }
    } catch (_) {
      _err('An error occurred. Please check your connection.');
    } finally {
      isSubmitting.value = false;
    }
  }

  String? validateHours(String? v) {
    if (v == null || v.trim().isEmpty) return 'Hours Worked is required';
    if (double.tryParse(v) == null)     return 'Please enter a valid number';
    if (double.parse(v) <= 0)           return 'Hours must be greater than 0';
    return null;
  }

  String? validateReason(String? v) {
    if (v == null || v.trim().isEmpty) return 'Reason for Overtime is required';
    return null;
  }

  void _err(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12));
}
