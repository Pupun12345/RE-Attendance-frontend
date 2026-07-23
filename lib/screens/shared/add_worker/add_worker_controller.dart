import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/utils/constants.dart';

class AddWorkerController extends GetxController {
  final Color primaryBlue = const Color(0xFF0D47A1);

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final userIdController = TextEditingController();
  final phoneController = TextEditingController();

  final isConfirmed = false.obs;
  final isSaving = false.obs;
  final profileImage = Rxn<File>();

  final ImagePicker _picker = ImagePicker();

  @override
  void onClose() {
    nameController.dispose();
    userIdController.dispose();
    phoneController.dispose();
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

  void saveWorker() async {
    if (!formKey.currentState!.validate()) return;

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
      request.fields['role'] = 'worker';
      request.fields['password'] = '123456';

      if (profileImage.value != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profileImage', profileImage.value!.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 201 && data['success'] == true) {
        Get.snackbar("Success", "Worker added successfully!",
            backgroundColor: Colors.green, colorText: Colors.white);
        Get.back(result: true);
      } else {
        Get.snackbar("Error", data['message'] ?? 'Failed to add worker.',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred. Please check your connection.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }
}
