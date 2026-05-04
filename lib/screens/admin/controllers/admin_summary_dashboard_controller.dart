// lib/screens/admin/controllers/admin_summary_dashboard_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

class AdminSummaryDashboardController extends GetxController {
  final isLoading       = true.obs;
  final totalSupervisors = 0.obs;
  final totalWorkers     = 0.obs;
  final totalManagement  = 0.obs;
  final presentToday     = 0.obs;
  final absentToday      = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) { _err('Not authorized.'); return; }

      final headers = {'Authorization': 'Bearer $token'};

      // --- 1. Users ---
      final usersRes = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/users'),
        headers: headers,
      );
      if (usersRes.statusCode == 200) {
        final users = (jsonDecode(usersRes.body)['users'] as List);
        totalSupervisors.value = users.where((u) => u['role'] == 'supervisor').length;
        totalWorkers.value     = users.where((u) => u['role'] == 'worker').length;
        totalManagement.value  = users.where((u) => u['role'] == 'management').length;
      }

      // --- 2. Attendance Summary ---
      final sumRes = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/attendance/summary/today'),
        headers: headers,
      );
      if (sumRes.statusCode == 200) {
        final d = jsonDecode(sumRes.body)['data'];
        presentToday.value = d['present'] ?? 0;
        absentToday.value  = d['absent']  ?? 0;
      }
    } catch (e) {
      _err('Error: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void _err(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12));
}
