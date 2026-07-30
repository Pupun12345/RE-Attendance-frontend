import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/models/user_model.dart';

import 'package:smartcare_app/utils/constants.dart';

class ManageUsersController extends GetxController {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final String? roleFilter;

  ManageUsersController({this.roleFilter});

  final users = <User>[].obs;
  final filteredUsers = <User>[].obs;
  final isLoading = true.obs;

  static const int pageSize = 20;
  final visibleCount = pageSize.obs;
  final isLoadingMore = false.obs;

  final searchController = TextEditingController();
  String? _token;

  List<User> get pagedUsers =>
      filteredUsers.take(visibleCount.value).toList();

  bool get hasMore => visibleCount.value < filteredUsers.length;

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore.value) return;
    isLoadingMore.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    visibleCount.value =
        (visibleCount.value + pageSize).clamp(0, filteredUsers.length);
    isLoadingMore.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    searchController.addListener(_filterUsers);
  }

  @override
  void onClose() {
    searchController.removeListener(_filterUsers);
    searchController.dispose();
    super.onClose();
  }

  String get title {
    if (roleFilter == 'worker') return "Manage Workers";
    if (roleFilter == 'supervisor') return "Manage Supervisors";
    if (roleFilter == 'management') return "Manage Management";
    return "Manage All Users";
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        Get.snackbar("Error", "Not authorized.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
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
        final loadedUsers = (data['users'] as List)
            .map((u) => User.fromJson(u))
            .toList()
            .cast<User>();
        users.value = loadedUsers;
        filteredUsers.value = List<User>.from(loadedUsers);
        visibleCount.value = pageSize;
        isLoadingMore.value = false;
      } else {
        Get.snackbar("Error", "Failed to load users.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: ${e.toString()}",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void _filterUsers() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredUsers.value = List<User>.from(users);
    } else {
      filteredUsers.value = users.where((user) {
        final name = user.name.toLowerCase();
        final role = user.role.toLowerCase();
        return name.contains(query) || role.contains(query);
      }).toList();
    }
    visibleCount.value = pageSize;
    isLoadingMore.value = false;
  }

  Future<void> deleteUser(String userId) async {
    if (_token == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to disable this user?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/users/$userId');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        users.removeWhere((u) => u.id == userId);
        filteredUsers.removeWhere((u) => u.id == userId);
        Get.snackbar("Success", "User disabled successfully",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", data['message'] ?? "Failed to delete user.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}
