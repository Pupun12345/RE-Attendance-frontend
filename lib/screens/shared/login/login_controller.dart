import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/admin/views/admin_dashboard_view.dart';
import 'package:smartcare_app/screens/supervisor/views/supervisor_dashboard_view.dart';
import 'package:smartcare_app/screens/management/management_dashboard_screen.dart';

import '../../../constant.dart';

class LoginController extends GetxController {
  final Color primaryBlue = const Color(0xFF0D47A1);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final obscurePassword = true.obs;
  final isLoggingIn = false.obs;
  final acceptedTerms = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  bool get canLogin => !isLoggingIn.value && acceptedTerms.value;

  void handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please enter email and password.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (!acceptedTerms.value) {
      Get.snackbar("Error", "Please accept Terms & Privacy to continue.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isLoggingIn.value = true;

    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final user = data['user'];
        final String role = user['role'];

        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(user));
        await prefs.setString('userName', user['name']);
        await prefs.setString('role', user['role']);

        if (role == 'admin') {
          Get.offAll(() => const AdminDashboardView());
        } else if (role == 'supervisor') {
          Get.offAll(() => const SupervisorDashboardView());
        } else if (role == 'management') {
          Get.offAll(() => const ManagementDashboardScreen());
        } else {
          Get.snackbar("Error", "Your role is not authorized to log in.",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
        }
      } else {
        Get.snackbar("Error", data['message'] ?? 'Invalid credentials.',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      print("this is errror$e");
      Get.snackbar("Error", "Could not connect to server. Check your API URL.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoggingIn.value = false;
    }
  }

  void handleForgotPassword(String email) async {
    if (email.isEmpty) return;
    final url = Uri.parse('$apiBaseUrl/api/v1/auth/forgotpassword');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      Get.back();
      Get.snackbar(
        data['success'] == true ? "Success" : "Error",
        data['message'],
        backgroundColor:
        data['success'] == true ? Colors.green : Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Server error. Could not send reset link.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Forgot Password"),
        content: TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(
            labelText: "Enter your registered email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => handleForgotPassword(emailCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}