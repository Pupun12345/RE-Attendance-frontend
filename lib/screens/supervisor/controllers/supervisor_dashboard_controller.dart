// lib/screens/supervisor/controllers/supervisor_dashboard_controller.dart

import 'dart:convert';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/screens/shared/login_screen.dart';
import 'package:flutter/material.dart';

import '../../shared/login/login_view.dart';

class SupervisorDashboardController extends GetxController {
  final selectedIndex = 0.obs;

  final userName = 'User Name'.obs;
  final userRole = 'Role'.obs;
  final userId = 'ID-000'.obs;
  final userEmail = 'email@example.com'.obs;
  final userPhone = '1234567890'.obs;
  final profileImageUrl = RxnString();
  final isLoadingProfile = true.obs;

  final allowCamera = false.obs;
  final allowLocation = false.obs;
  final allowContact = false.obs;

  final location = 'Fetching location...'.obs;
  final searchController = TextEditingController();

  bool get canContinue => allowCamera.value || allowLocation.value || allowContact.value;

  @override
  void onInit() {
    super.onInit();
    fetchLocation();
    loadUserData();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void changeTab(int index) => selectedIndex.value = index;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userData = jsonDecode(userString) as Map<String, dynamic>;
      userName.value = userData['name'] ?? 'User Name';
      userRole.value = userData['role'] ?? 'Role';
      userId.value = userData['userId'] ?? 'ID-000';
      userEmail.value = userData['email'] ?? 'email@example.com';
      userPhone.value = userData['phone'] ?? '1234567890';
      profileImageUrl.value = userData['profileImageUrl'];
    }
    isLoadingProfile.value = false;
  }

  Future<void> fetchLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { location.value = 'GPS not enabled'; return; }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { location.value = 'Location permission denied'; return; }
    }
    if (permission == LocationPermission.deniedForever) {
      location.value = 'Location permission permanently denied';
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    location.value = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(() => const LoginView());
  }

  String get capitalizedRole {
    if (userRole.value.isEmpty) return '';
    return userRole.value[0].toUpperCase() + userRole.value.substring(1);
  }
}