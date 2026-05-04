import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

class HolidayModel {
  final String title;
  final DateTime date;
  final String type;

  HolidayModel(
      {required this.title, required this.date, required this.type});

  factory HolidayModel.fromJson(Map<String, dynamic> json) => HolidayModel(
        title: json['name'],
        date: DateTime.parse(json['date']),
        type: json['type'],
      );
}

class HolidayCalendarController extends GetxController {
  final Color themeBlue = const Color(0xFF0B3B8C);

  final holidays = <HolidayModel>[].obs;
  final isLoading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchHolidays();
  }

  Future<void> fetchHolidays() async {
    isLoading.value = true;
    error.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/holidays"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> holidaysJson = responseData['holidays'];
        holidays.value =
            holidaysJson.map((j) => HolidayModel.fromJson(j)).toList();
      } else {
        error.value = "Failed to load holidays.";
      }
    } catch (e) {
      error.value = "Could not connect to server. Check your network.";
    } finally {
      isLoading.value = false;
    }
  }

  String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  IconData getIconForType(String type) => type == 'national'
      ? Icons.flag_rounded
      : Icons.business_center_rounded;

  Color getColorForType(String type) =>
      type == 'national' ? Colors.green : Colors.orange;
}
