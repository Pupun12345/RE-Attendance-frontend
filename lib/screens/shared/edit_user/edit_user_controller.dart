import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/models/user_model.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

class EditUserController extends GetxController {
  final Color primaryBlue = const Color(0xFF0D47A1);

  final User user;
  EditUserController({required this.user});

  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController userIdController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  final selectedRole = ''.obs;
  final isSaving = false.obs;
  final isDisabling = false.obs;
  final isUserDisabled = false.obs;

  final selectedImageFile = Rxn<File>();
  final existingImageUrl = RxnString();

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: user.name);
    userIdController = TextEditingController(text: user.userId);
    phoneController = TextEditingController(text: user.phone);
    emailController = TextEditingController(text: user.email ?? '');
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    selectedRole.value = user.role;
    existingImageUrl.value = user.profileImageUrl;
    isUserDisabled.value = !user.isActive;
  }

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

  void showImageSourceSheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Change Profile Photo",
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Get.back();
                        _pickImage(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Get.back();
                        _pickImage(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Gallery"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        selectedImageFile.value = File(picked.path);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick image: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> toggleUserStatus() async {
    isDisabling.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('$apiBaseUrl/api/v1/users/${user.id}');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        isUserDisabled.value = !isUserDisabled.value;
        Get.snackbar(
          isUserDisabled.value ? "Disabled" : "Enabled",
          isUserDisabled.value
              ? "User disabled successfully"
              : "User enabled successfully",
          backgroundColor:
              isUserDisabled.value ? Colors.red : Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar("Error", data['message'] ?? "Failed to update user status.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Error occurred",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isDisabling.value = false;
    }
  }

  Future<void> updateUser() async {
    if (!formKey.currentState!.validate()) return;

    if (newPasswordController.text.isNotEmpty) {
      if (newPasswordController.text != confirmPasswordController.text) {
        Get.snackbar("Error", "Passwords do not match.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        return;
      }
    }

    isSaving.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('$apiBaseUrl/api/v1/users/${user.id}');
      final Map<String, dynamic> body = {
        'name': nameController.text,
        'userId': userIdController.text,
        'phone': phoneController.text,
        'role': selectedRole.value,
      };

      if (emailController.text.isNotEmpty) {
        body['email'] = emailController.text;
      }

      if (newPasswordController.text.isNotEmpty) {
        body['password'] = newPasswordController.text;
      }

      if (selectedImageFile.value != null) {
        final bytes = await selectedImageFile.value!.readAsBytes();
        body['profileImageBase64'] = base64Encode(bytes);
      }

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Get.snackbar("Success", "User updated successfully!",
            backgroundColor: Colors.green, colorText: Colors.white);

      } else {
        Get.snackbar("Error", data['message'] ?? 'Failed to update user.',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Connection error",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }
}
