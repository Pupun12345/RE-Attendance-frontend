// lib/screens/admin/controllers/admin_pending_attendance_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/models/pending_attendance_model.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

enum PendingCategory { supervisor, management, worker }

class AdminPendingAttendanceController extends GetxController {
  final allRequests      = <PendingAttendance>[].obs;
  final isLoading        = true.obs;
  final selectedCategory = PendingCategory.supervisor.obs;

  String? _token;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  // ── Computed ───────────────────────────────────────────────────────────
  List<PendingAttendance> get filtered {
    final role = _roleFor(selectedCategory.value).toLowerCase();
    return allRequests
        .where((r) => _extractRole(r.user).toLowerCase() == role)
        .toList();
  }

  int countFor(PendingCategory cat) {
    final role = _roleFor(cat).toLowerCase();
    return allRequests
        .where((r) => _extractRole(r.user).toLowerCase() == role)
        .length;
  }

  String _roleFor(PendingCategory c) {
    switch (c) {
      case PendingCategory.supervisor:  return 'supervisor';
      case PendingCategory.management:  return 'management';
      case PendingCategory.worker:      return 'worker';
    }
  }

  String labelFor(PendingCategory c) {
    switch (c) {
      case PendingCategory.supervisor:  return 'Supervisor';
      case PendingCategory.management:  return 'Management';
      case PendingCategory.worker:      return 'Workers';
    }
  }

  IconData iconFor(PendingCategory c) {
    switch (c) {
      case PendingCategory.supervisor:  return LucideIcons.userCheck;
      case PendingCategory.management:  return LucideIcons.briefcase;
      case PendingCategory.worker:      return LucideIcons.users;
    }
  }

  String _extractRole(PendingUser user) {
    final uid = user.userId.toUpperCase();
    if (uid.startsWith('TS')) return 'supervisor';
    if (uid.startsWith('TW')) return 'worker';
    return 'management'; // VT, YH, TE, etc.
  }

  // ── API ────────────────────────────────────────────────────────────────
  Future<void> fetchRequests() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) { _err('Not authorized.'); return; }

      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/attendance/pending'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        allRequests.value = (data['data'] as List)
            .map((r) => PendingAttendance.fromJson(r))
            .toList();
      } else {
        _err('Failed to load pending requests.');
      }
    } catch (e) {
      _err('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleAction(PendingAttendance req, bool approve) async {
    if (_token == null) { _err('Not authorized.'); return; }
    final action = approve ? 'approve' : 'reject';

    try {
      final res = await http.put(
        Uri.parse('$apiBaseUrl/api/v1/attendance/${req.id}/$action'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        allRequests.remove(req);
        _ok(approve
            ? '✅ ${req.user.name} approved!'
            : '❌ ${req.user.name} rejected!',
            approve);
      } else {
        final d = jsonDecode(res.body);
        _err(d['message'] ?? 'Failed to process.');
      }
    } catch (e) {
      _err('Error: $e');
    }
  }

  void _ok(String msg, bool success) => Get.snackbar('', msg,
      backgroundColor: success ? Colors.green : Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12));

  void _err(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12));
}
