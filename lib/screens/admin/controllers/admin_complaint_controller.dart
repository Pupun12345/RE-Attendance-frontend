// lib/screens/admin/controllers/admin_complaint_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

// ─── Models ────────────────────────────────────────────────────────────────

class ComplaintUser {
  final String name;
  final String userId;
  ComplaintUser({required this.name, required this.userId});

  factory ComplaintUser.fromJson(dynamic json) {
    if (json == null) return ComplaintUser(name: 'Unknown', userId: 'N/A');
    if (json is String) return ComplaintUser(name: 'Unknown', userId: json);
    if (json is Map<String, dynamic>) {
      return ComplaintUser(name: json['name'] ?? 'Unknown', userId: json['userId'] ?? 'N/A');
    }
    return ComplaintUser(name: 'Unknown', userId: 'N/A');
  }
}

class AdminComplaint {
  final String id;
  final String title;
  final String description;
  final ComplaintUser user;
  final ComplaintUser submittedBy;
  final DateTime createdAt;

  AdminComplaint({
    required this.id,
    required this.title,
    required this.description,
    required this.user,
    required this.submittedBy,
    required this.createdAt,
  });

  factory AdminComplaint.fromJson(Map<String, dynamic> json) => AdminComplaint(
        id: json['_id'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        user: ComplaintUser.fromJson(json['user']),
        submittedBy: ComplaintUser.fromJson(json['submittedBy'] ?? json['user']),
        createdAt: DateTime.parse(json['createdAt']),
      );

  bool get isByProxy => user.userId != submittedBy.userId;
  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdAt);
}

// ─── Controller ────────────────────────────────────────────────────────────

class AdminComplaintController extends GetxController {
  final complaints = <AdminComplaint>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/complaints'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        complaints.value = (data['complaints'] as List)
            .map((c) => AdminComplaint.fromJson(c))
            .where((c) => c.createdAt.isAfter(cutoff))
            .toList();
      }
    } catch (e) {
      debugPrint('Complaint fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
