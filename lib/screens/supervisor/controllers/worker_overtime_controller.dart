// lib/screens/supervisor/controllers/worker_overtime_controller.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/utils/constants.dart';

class WorkerOvertimeController extends GetxController {
  late String workerName;
  late String workerId;
  late String workerDbId;

  final hoursController = TextEditingController();
  final reasonController = TextEditingController();

  final dateTimeText = ''.obs;
  final isSubmitting = false.obs;

  Timer? _timer;

  void init({required String name, required String userId, required String dbId}) {
    workerName = name;
    workerId = userId;
    workerDbId = dbId;
  }

  @override
  void onInit() {
    super.onInit();
    _startDateTimeTicker();
  }

  @override
  void onClose() {
    _timer?.cancel();
    hoursController.dispose();
    reasonController.dispose();
    super.onClose();
  }

  void _startDateTimeTicker() {
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
  }

  void _updateDateTime() {
    final now = DateTime.now();
    dateTimeText.value =
    '${DateFormat('EEE, dd MMM yyyy').format(now)}  ${DateFormat('hh:mm:ss a').format(now)}';
  }

  Future<void> submitOvertime() async {
    if (hoursController.text.trim().isEmpty || reasonController.text.trim().isEmpty) {
      _showSnack('Please enter hours and reason', false);
      return;
    }
    final double? hours = double.tryParse(hoursController.text);
    if (hours == null || hours <= 0) {
      _showSnack('Enter valid overtime hours', false);
      return;
    }

    isSubmitting.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final designation = prefs.getString('designation') ?? 'Worker';

      if (token == null) { _showSnack('Authentication error. Login again.', false); return; }

      final response = await http.post(
        Uri.parse(apiOvertime),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': DateTime.now().toIso8601String(),
          'hours': hours,
          'reason': reasonController.text.trim(),
          'workerId': workerDbId,
          'designation': designation,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        _showSnack('Overtime submitted successfully', true);

      } else {
        _showSnack(data['message'] ?? 'Submission failed', false);
      }
    } catch (_) {
      _showSnack('Something went wrong', false);
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showSnack(String msg, bool success) {
    Get.snackbar('', msg,
        backgroundColor: success ? Colors.green : Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12));
  }
}