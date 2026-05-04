import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/screens/admin/views/admin_dashboard_view.dart';
import 'package:smartcare_app/screens/supervisor/views/supervisor_dashboard_view.dart';
import 'package:smartcare_app/screens/management/management_dashboard_screen.dart';


import '../login/login_view.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userString = prefs.getString('user');

      if (token != null && token.isNotEmpty && userString != null) {
        final Map<String, dynamic> user = jsonDecode(userString);
        final String role = user['role'];

        if (role == 'admin') {
          Get.offAll(() => const AdminDashboardView());
        } else if (role == 'supervisor') {
          Get.offAll(() => const SupervisorDashboardView());
        } else if (role == 'management') {
          Get.offAll(() => const ManagementDashboardScreen());
        } else {
          Get.offAll(() => const LoginView());
        }
      } else {
        Get.offAll(() => const LoginView());
      }
    } catch (e) {
      Get.offAll(() => const LoginView());
    }
  }
}