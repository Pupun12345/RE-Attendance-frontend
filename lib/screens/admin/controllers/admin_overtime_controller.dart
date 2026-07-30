// lib/screens/admin/controllers/admin_overtime_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/models/overtime_model.dart';

import 'package:smartcare_app/utils/constants.dart';

class AdminOvertimeController extends GetxController
    with GetTickerProviderStateMixin {
  late TabController tabController;

  final isLoading = true.obs;
  final isActionLoading = false.obs;
  final pendingList  = <OvertimeRecord>[].obs;
  final approvedList = <OvertimeRecord>[].obs;
  final rejectedList = <OvertimeRecord>[].obs;

  static const int pageSize = 20;
  final pendingVisible  = pageSize.obs;
  final approvedVisible = pageSize.obs;
  final rejectedVisible = pageSize.obs;

  // Drives the small bottom-of-list spinner while a scroll-triggered
  // "load more" is in flight, so auto-loading doesn't fire twice for the
  // same scroll gesture.
  final pendingLoadingMore  = false.obs;
  final approvedLoadingMore = false.obs;
  final rejectedLoadingMore = false.obs;

  List<OvertimeRecord> get pagedPending =>
      pendingList.take(pendingVisible.value).toList();
  List<OvertimeRecord> get pagedApproved =>
      approvedList.take(approvedVisible.value).toList();
  List<OvertimeRecord> get pagedRejected =>
      rejectedList.take(rejectedVisible.value).toList();

  bool get pendingHasMore  => pendingVisible.value  < pendingList.length;
  bool get approvedHasMore => approvedVisible.value < approvedList.length;
  bool get rejectedHasMore => rejectedVisible.value < rejectedList.length;

  Future<void> loadMorePending() async {
    if (!pendingHasMore || pendingLoadingMore.value) return;
    pendingLoadingMore.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    pendingVisible.value =
        (pendingVisible.value + pageSize).clamp(0, pendingList.length);
    pendingLoadingMore.value = false;
  }

  Future<void> loadMoreApproved() async {
    if (!approvedHasMore || approvedLoadingMore.value) return;
    approvedLoadingMore.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    approvedVisible.value =
        (approvedVisible.value + pageSize).clamp(0, approvedList.length);
    approvedLoadingMore.value = false;
  }

  Future<void> loadMoreRejected() async {
    if (!rejectedHasMore || rejectedLoadingMore.value) return;
    rejectedLoadingMore.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    rejectedVisible.value =
        (rejectedVisible.value + pageSize).clamp(0, rejectedList.length);
    rejectedLoadingMore.value = false;
  }

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
        pendingVisible.value  = pageSize;
        approvedVisible.value = pageSize;
        rejectedVisible.value = pageSize;
        pendingLoadingMore.value  = false;
        approvedLoadingMore.value = false;
        rejectedLoadingMore.value = false;
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
