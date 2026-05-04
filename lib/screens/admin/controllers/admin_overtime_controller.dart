// lib/screens/admin/controllers/admin_overtime_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/models/overtime_model.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

class AdminOvertimeController extends GetxController
    with GetTickerProviderStateMixin {
  late TabController tabController;

  final isLoading = true.obs;
  final isActionLoading = false.obs;
  final pendingList  = <OvertimeRecord>[].obs;
  final approvedList = <OvertimeRecord>[].obs;
  final rejectedList = <OvertimeRecord>[].obs;

  String? _token;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    fetchAllOvertime();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> fetchAllOvertime() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _err('Not authorized.');
        return;
      }

      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/overtime'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (res.statusCode == 200) {
        final all = (jsonDecode(res.body)['data'] as List)
            .map((r) => OvertimeRecord.fromJson(r))
            .toList();
        pendingList.value  = all.where((r) => r.status == 'pending').toList();
        approvedList.value = all.where((r) => r.status == 'approved').toList();
        rejectedList.value = all.where((r) => r.status == 'rejected').toList();
      } else {
        _err('Failed to load overtime records.');
      }
    } catch (e) {
      _err('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleAction(OvertimeRecord record, bool approve) async {
    if (_token == null) return;
    if (isActionLoading.value) return;
    final action = approve ? 'approve' : 'reject';
    isActionLoading.value = true;

    try {
      final res = await http.put(
        Uri.parse('$apiBaseUrl/api/v1/overtime/${record.id}/$action'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        await fetchAllOvertime();
      } else {
        _err('Failed to $action overtime request.');
      }
    } catch (e) {
      _err('Error: $e');
    } finally {
      isActionLoading.value = false;
    }
  }

  void _err(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12));
}
