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

class SubmitComplaintController extends GetxController {
  final Color themeBlue = const Color(0xFF0B3B8C);

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final searchController = TextEditingController();

  final selectedImage = Rxn<File>();
  final isSubmitting = false.obs;
  final isLoadingWorkers = true.obs;

  final allWorkers = <dynamic>[].obs;
  final filteredWorkers = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchWorkers();
    searchController.addListener(_filterWorkers);
  }



  Future<void> refreshData() async {
    if (allWorkers.isEmpty) await fetchWorkers();
  }

  Future<void> fetchWorkers() async {
    isLoadingWorkers.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/users?role=worker"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        allWorkers.value = data['users'];
        filteredWorkers.value = allWorkers.toList();
      }
    } catch (e) {
      // silent fail
    } finally {
      isLoadingWorkers.value = false;
    }
  }

  void _filterWorkers() {
    final query = searchController.text.toLowerCase();
    filteredWorkers.value = allWorkers.where((worker) {
      final name = worker['name']?.toString().toLowerCase() ?? '';
      final userId = worker['userId']?.toString().toLowerCase() ?? '';
      return name.contains(query) || userId.contains(query);
    }).toList();
  }

  Future<void> captureImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) selectedImage.value = File(picked.path);
  }

  Future<void> pickImageFromGallery() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) selectedImage.value = File(picked.path);
  }

  Future<void> submitComplaint() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      Get.snackbar("Error", "Title and description cannot be empty.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      var request = http.MultipartRequest(
          'POST', Uri.parse("$apiBaseUrl/api/v1/complaints"));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = titleController.text;
      request.fields['description'] = descriptionController.text;

      if (selectedImage.value != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'complaintImage', selectedImage.value!.path,
            contentType: MediaType('image', 'jpeg')));
      }

      final response =
          await http.Response.fromStream(await request.send());

      if (response.statusCode == 201) {
        Get.snackbar("Success", "Complaint submitted!",
            backgroundColor: Colors.green, colorText: Colors.white);
        titleController.clear();
        descriptionController.clear();
        selectedImage.value = null;
      } else {
        Get.snackbar("Error", "Failed to submit",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Error: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
