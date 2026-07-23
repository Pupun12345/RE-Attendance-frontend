// lib/screens/shared/controllers/manage_users_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/models/user_model.dart';

import 'package:smartcare_app/utils/constants.dart';

class ManageUsersController extends GetxController {
  final String? roleFilter;
  ManageUsersController({this.roleFilter});

  final searchController = TextEditingController();

  final allUsers = <User>[].obs;
  final filteredUsers = <User>[].obs;
  final isLoading = true.obs;

  String? _token;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    searchController.addListener(_filterUsers);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _showSnack('Not authorized.', false);
        return;
      }

      String urlString = '$apiBaseUrl/api/v1/users';
      if (roleFilter != null) urlString += '?role=$roleFilter';

      final response = await http.get(
        Uri.parse(urlString),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loaded = (data['users'] as List)
            .map((e) => User.fromJson(e))
            .toList();
        allUsers.value = loaded;
        _filterUsers();
      } else {
        _showSnack('Failed to load users.', false);
      }
    } catch (_) {
      _showSnack('Network error. Please try again.', false);
    } finally {
      isLoading.value = false;
    }
  }

  void _filterUsers() {
    final q = searchController.text.toLowerCase();
    filteredUsers.value = q.isEmpty
        ? List<User>.from(allUsers)
        : allUsers.where((u) =>
    u.name.toLowerCase().contains(q) ||
        u.role.toLowerCase().contains(q)).toList();
  }

  Future<void> deleteUser(String userId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to disable this user?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final res = await http.delete(
        Uri.parse('$apiBaseUrl/api/v1/users/$userId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        allUsers.removeWhere((u) => u.id == userId);
        filteredUsers.removeWhere((u) => u.id == userId);
        _showSnack('User disabled successfully', true);
      } else {
        _showSnack(data['message'] ?? 'Failed to delete user.', false);
      }
    } catch (_) {
      _showSnack('An error occurred.', false);
    }
  }

  void _showSnack(String msg, bool success) {
    Get.snackbar('', msg,
        backgroundColor: success ? Colors.green : Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12));
  }

  String get pageTitle {
    if (roleFilter == 'worker') return 'Manage Workers';
    if (roleFilter == 'supervisor') return 'Manage Supervisors';
    if (roleFilter == 'management') return 'Manage Management';
    return 'Manage All Users';
  }
}