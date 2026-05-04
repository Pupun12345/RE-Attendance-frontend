// lib/screens/supervisor/controllers/worker_complaint_controller.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

class WorkerComplaintController extends GetxController {
  late String workerName;
  late String workerId;
  late String workerDbId;

  final titleController = TextEditingController();
  final descController = TextEditingController();

  final selectedImage = Rxn<File>();
  final isSubmitting = false.obs;

  final _picker = ImagePicker();

  void init({required String name, required String userId, required String dbId}) {
    workerName = name;
    workerId = userId;
    workerDbId = dbId;
  }

  @override
  void onClose() {
    titleController.dispose();
    descController.dispose();
    super.onClose();
  }

  Future<void> pickFromCamera() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (img != null) selectedImage.value = File(img.path);
  }

  Future<void> pickFromGallery() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) selectedImage.value = File(img.path);
  }

  Future<void> submitComplaint() async {
    if (titleController.text.trim().isEmpty || descController.text.trim().isEmpty) {
      _showSnack('Please fill title and description.', false);
      return;
    }

    isSubmitting.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final request = http.MultipartRequest('POST', Uri.parse(apiComplaints));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = titleController.text.trim();
      request.fields['description'] = descController.text.trim();
      request.fields['workerId'] = workerDbId;

      if (selectedImage.value != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'complaintImage',
          selectedImage.value!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 201) {
        _showSnack('Complaint Submitted Successfully!', true);


      } else {
        final data = jsonDecode(response.body);
        _showSnack(data['message'] ?? 'Failed to submit', false);
      }
    } catch (e) {
      _showSnack('Connection error: $e', false);
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showSnack(String msg, bool success) {
    Get.snackbar('', msg,
        backgroundColor: success ? Colors.green : Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12));
  }
}