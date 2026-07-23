// lib/screens/supervisor/controllers/attendance_detail_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/utils/constants.dart';

class AttendanceDetailController extends GetxController {
  final isLoading = true.obs;
  final selfAttendanceList = <dynamic>[].obs;
  final employeeList = <dynamic>[].obs;
  final filteredEmployeeList = <dynamic>[].obs;
  final selectedEmployeeFilter = Rxn<String>();

  final presentCount = 0.obs;
  final absentCount = 0.obs;
  final lateCount = 0.obs;
  final leaveCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    ever(employeeList, (_) => _applyFilter());
    ever(selectedEmployeeFilter, (_) => _applyFilter());
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchSelfAttendanceHistory(),
        _fetchEmployeeDailyStatus(),
      ]);
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchSelfAttendanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userString = prefs.getString('user');
    if (token == null || userString == null) return;

    final user = jsonDecode(userString);
    final String myUserId = user['id'] ?? user['_id'];

    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final dateFormat = DateFormat('yyyy-MM-dd');

    final url = Uri.parse(
      apiAttendanceDailyRange(
        dateFormat.format(thirtyDaysAgo),
        dateFormat.format(now),
      ),
    );

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allRecords = data['data'];

        final myRecords = allRecords.where((record) {
          if (record['user'] is Map) {
            return record['user']['_id'] == myUserId || record['user']['id'] == myUserId;
          }
          return record['user'] == myUserId;
        }).toList();

        myRecords.sort((a, b) {
          return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
        });

        selfAttendanceList.value = myRecords;
      }
    } catch (e) {
      debugPrint("Error fetching self attendance: $e");
    }
  }

  Future<void> _fetchEmployeeDailyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(apiAttendanceStatusToday),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> employees = data['data'];

        int present = 0, absent = 0, leave = 0, late = 0;
        for (var emp in employees) {
          final status = (emp['status'] ?? 'absent').toString().toLowerCase();
          if (status == 'present') {
            present++;
          } else if (status == 'absent') {
            absent++;
          } else if (status == 'leave') {
            leave++;
          } else if (status == 'late') {
            late++;
          }
        }

        employeeList.value = employees;
        presentCount.value = present;
        absentCount.value = absent;
        leaveCount.value = leave;
        lateCount.value = late;
      }
    } catch (e) {
      debugPrint("Error fetching employee status: $e");
    }
  }

  String formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      final utcTime = DateTime.parse(isoString);
      final istTime = utcTime.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('hh:mm a').format(istTime);
    } catch (_) {
      return '--:--';
    }
  }

  String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final utcDate = DateTime.parse(isoString);
      final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('dd MMM, yyyy').format(istDate);
    } catch (_) {
      return '';
    }
  }

  void _applyFilter() {
    if (selectedEmployeeFilter.value == null) {
      filteredEmployeeList.value = employeeList;
    } else {
      filteredEmployeeList.value = employeeList
          .where((emp) => (emp['status'] ?? 'absent')
              .toString()
              .toLowerCase()
              .contains(selectedEmployeeFilter.value!.toLowerCase()))
          .toList();
    }
  }

  void setEmployeeFilter(String? status) {
    selectedEmployeeFilter.value = status;
  }
}