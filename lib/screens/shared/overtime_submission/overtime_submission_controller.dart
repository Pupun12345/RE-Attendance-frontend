// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smartcare_app/utils/constants.dart';
//
// import '../../../constant.dart';
//
// class OvertimeSubmissionController extends GetxController {
//   final Color themeBlue = const Color(0xFF0B3B8C);
//
//   final selectedDate = DateTime.now().obs;
//   final fromTime = Rxn<TimeOfDay>();
//   final toTime = Rxn<TimeOfDay>();
//   final isSubmitting = false.obs;
//
//   final reasonController = TextEditingController();
//
//   @override
//   void onClose() {
//     reasonController.dispose();
//     super.onClose();
//   }
//
//   String get formattedDate =>
//       DateFormat('EEE, dd MMM yyyy').format(selectedDate.value);
//
//   String fromTimeLabel(BuildContext context) =>
//       fromTime.value == null
//           ? "Select From Time"
//           : fromTime.value!.format(context);
//
//   String toTimeLabel(BuildContext context) =>
//       toTime.value == null ? "Select To Time" : toTime.value!.format(context);
//
//   Future<void> pickDate(BuildContext context) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate.value,
//       firstDate: DateTime.now().subtract(const Duration(days: 30)),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) selectedDate.value = picked;
//   }
//
//   Future<void> pickFromTime(BuildContext context) async {
//     final picked = await showTimePicker(
//         context: context, initialTime: TimeOfDay.now());
//     if (picked != null) fromTime.value = picked;
//   }
//
//   Future<void> pickToTime(BuildContext context) async {
//     final picked = await showTimePicker(
//         context: context, initialTime: TimeOfDay.now());
//     if (picked != null) toTime.value = picked;
//   }
//
//   Future<void> submitOvertime() async {
//     if (fromTime.value == null || toTime.value == null) {
//       Get.snackbar("Error", "Please select From Time and To Time",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//       return;
//     }
//
//     isSubmitting.value = true;
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//
//       if (token == null) {
//         Get.snackbar("Error", "Authentication error. Please login again.",
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//         return;
//       }
//
//       final fromDateTime = DateTime(
//         selectedDate.value.year,
//         selectedDate.value.month,
//         selectedDate.value.day,
//         fromTime.value!.hour,
//         fromTime.value!.minute,
//       );
//
//       final toDateTime = DateTime(
//         selectedDate.value.year,
//         selectedDate.value.month,
//         selectedDate.value.day,
//         toTime.value!.hour,
//         toTime.value!.minute,
//       );
//
//       final duration = toDateTime.difference(fromDateTime);
//       final double totalHours = duration.inMinutes / 60;
//
//       if (totalHours <= 0) {
//         Get.snackbar("Error", "Invalid time selection",
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//         return;
//       }
//
//       final response = await http.post(
//         Uri.parse('$apiBaseUrl/api/v1/overtime'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           "date": selectedDate.value.toIso8601String(),
//           "hours": totalHours,
//           "reason": reasonController.text.trim(),
//         }),
//       );
//
//       final data = jsonDecode(response.body);
//
//       if (response.statusCode == 201 && data['success'] == true) {
//         Get.snackbar("Success", "Overtime submitted successfully",
//             backgroundColor: Colors.green, colorText: Colors.white);
//         Get.back();
//       } else {
//         Get.snackbar("Error", data['message'] ?? "Submission failed",
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Something went wrong",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//     } finally {
//       isSubmitting.value = false;
//     }
//   }
// }




import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

import '../../../constant.dart';

class OvertimeSubmissionController extends GetxController {
  final Color themeBlue = const Color(0xFF0B3B8C);

  final selectedDate = DateTime.now().obs;
  final isSubmitting = false.obs;

  final overtimeHoursController = TextEditingController();
  final reasonController = TextEditingController();

  @override
  void onClose() {
    overtimeHoursController.dispose();
    reasonController.dispose();
    super.onClose();
  }

  String get formattedDate =>
      DateFormat('EEE, dd MMM yyyy').format(selectedDate.value);

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) selectedDate.value = picked;
  }

  Future<void> submitOvertime() async {
    final hoursText = overtimeHoursController.text.trim();
    final double? totalHours = double.tryParse(hoursText);

    if (totalHours == null || totalHours <= 0) {
      Get.snackbar("Error", "Please enter valid overtime hours",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        Get.snackbar("Error", "Authentication error. Please login again.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        return;
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/overtime'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "date": selectedDate.value.toIso8601String(),
          "hours": totalHours,
          "reason": reasonController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        Get.snackbar("Success", "Overtime submitted successfully",
            backgroundColor: Colors.green, colorText: Colors.white);

      } else {
        Get.snackbar("Error", data['message'] ?? "Submission failed",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }
}