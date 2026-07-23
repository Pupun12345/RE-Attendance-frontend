// lib/screens/supervisor/controllers/workers_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/utils/constants.dart';

class Worker {
  final String id;
  final String name;
  final String userId;
  final String? profileImageUrl;

  Worker({
    required this.id,
    required this.name,
    required this.userId,
    this.profileImageUrl,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['_id'],
      name: json['name'],
      userId: json['userId'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class WorkersController extends GetxController {
  final searchController = TextEditingController();

  final allWorkers = <Worker>[].obs;
  final filteredWorkers = <Worker>[].obs;
  final isLoading = true.obs;
  final errorMsg = RxnString();

  final dummyWorker = Worker(
    id: 'dummy-1',
    name: 'umesh1402',
    userId: 'UMS1402',
    profileImageUrl: null,
  );

  @override
  void onInit() {
    super.onInit();
    fetchWorkers();
    searchController.addListener(filterWorkers);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchWorkers() async {
    isLoading.value = true;
    errorMsg.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(apiWorkers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> usersJson = responseData['users'];
        allWorkers.value = usersJson.map((j) => Worker.fromJson(j)).toList();
        filterWorkers();
      } else {
        errorMsg.value = "Failed to load workers.";
      }
    } catch (_) {
      errorMsg.value = "Could not connect to server. Check your network.";
    } finally {
      isLoading.value = false;
    }
  }

  void filterWorkers() {
    final query = searchController.text.toLowerCase();
    filteredWorkers.value = allWorkers.where((w) {
      return w.name.toLowerCase().contains(query) ||
          w.userId.toLowerCase().contains(query);
    }).toList();
  }

  void setInitialQuery(String? query) {
    if (query != null && query.isNotEmpty) {
      searchController.text = query;
    }
  }
}