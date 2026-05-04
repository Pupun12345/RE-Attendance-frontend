import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

class AddManagementStaffController extends GetxController {
  final Color primaryBlue = const Color(0xFF0D47A1);

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final userIdController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isConfirmed = false.obs;
  final isSaving = false.obs;
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final profileImage = Rxn<File>();

  final ImagePicker _picker = ImagePicker();

  @override
  void onClose() {
    nameController.dispose();
    userIdController.dispose();
    phoneController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedImage =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedImage != null) {
      profileImage.value = File(pickedImage.path);
    }
    Get.back();
  }

  void showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("Take Photo"),
              onTap: () => pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.green),
              title: const Text("Choose from Gallery"),
              onTap: () => pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.redAccent),
              title: const Text("Cancel"),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  void saveManagementStaff() async {
    if (!formKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar("Error", "Passwords do not match!",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (!isConfirmed.value) {
      Get.snackbar("Error", "Please confirm company policy before saving.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isSaving.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Get.snackbar("Error", "Authentication error. Please log in again.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/users');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = nameController.text;
      request.fields['userId'] = userIdController.text;
      request.fields['phone'] = phoneController.text;
      request.fields['email'] = emailController.text;
      request.fields['password'] = newPasswordController.text;
      request.fields['role'] = 'management';

      if (profileImage.value != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profileImage', profileImage.value!.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 201 && data['success'] == true) {
        Get.snackbar("Success", "Management Staff added successfully!",
            backgroundColor: Colors.green, colorText: Colors.white);
        Get.back(result: true);
      } else {
        Get.snackbar("Error", data['message'] ?? 'Failed to add staff.',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred. Please check your connection.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSaving.value = false;
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
    final emailController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Forgot Password"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: "Enter your registered email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () =>
                handleForgotPassword(emailController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}
