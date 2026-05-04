// lib/screens/admin/controllers/admin_system_configuration_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSystemConfigurationController extends GetxController {
  final isLoading = true.obs;

  // Text Controllers
  final companyNameCtrl = TextEditingController();
  final emailCtrl       = TextEditingController();
  final contactCtrl     = TextEditingController();
  final locationCtrl    = TextEditingController();

  // Observables
  final startTime            = const TimeOfDay(hour: 9,  minute: 0).obs;
  final endTime              = const TimeOfDay(hour: 18, minute: 0).obs;
  final overtimeEnabled      = true.obs;
  final autoLockAttendance   = false.obs;
  final darkMode             = false.obs;
  final notificationsEnabled = true.obs;
  final backupFrequency      = 'Weekly'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadConfig();
  }

  @override
  void onClose() {
    companyNameCtrl.dispose();
    emailCtrl.dispose();
    contactCtrl.dispose();
    locationCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadConfig() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();

    companyNameCtrl.text = prefs.getString('config_companyName') ?? 'SmartCare Technologies';
    emailCtrl.text       = prefs.getString('config_email')       ?? 'admin@smartcare.com';
    contactCtrl.text     = prefs.getString('config_contact')     ?? '+91 9876543210';
    locationCtrl.text    = prefs.getString('config_location')    ?? 'Bhubaneswar, Odisha';

    overtimeEnabled.value      = prefs.getBool('config_overtime')      ?? true;
    autoLockAttendance.value   = prefs.getBool('config_autoLock')      ?? false;
    darkMode.value             = prefs.getBool('config_darkMode')      ?? false;
    notificationsEnabled.value = prefs.getBool('config_notifications') ?? true;
    backupFrequency.value      = prefs.getString('config_backup')      ?? 'Weekly';

    startTime.value = TimeOfDay(
      hour:   prefs.getInt('config_startTime_hour') ?? 9,
      minute: prefs.getInt('config_startTime_min')  ?? 0,
    );
    endTime.value = TimeOfDay(
      hour:   prefs.getInt('config_endTime_hour') ?? 18,
      minute: prefs.getInt('config_endTime_min')  ?? 0,
    );

    isLoading.value = false;
  }

  Future<void> pickTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime.value : endTime.value,
    );
    if (picked != null) {
      if (isStart) startTime.value = picked;
      else endTime.value = picked;
    }
  }

  Future<void> saveConfig() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('config_companyName', companyNameCtrl.text);
    await prefs.setString('config_email',       emailCtrl.text);
    await prefs.setString('config_contact',     contactCtrl.text);
    await prefs.setString('config_location',    locationCtrl.text);

    await prefs.setBool('config_overtime',      overtimeEnabled.value);
    await prefs.setBool('config_autoLock',      autoLockAttendance.value);
    await prefs.setBool('config_darkMode',      darkMode.value);
    await prefs.setBool('config_notifications', notificationsEnabled.value);

    await prefs.setString('config_backup', backupFrequency.value);

    await prefs.setInt('config_startTime_hour', startTime.value.hour);
    await prefs.setInt('config_startTime_min',  startTime.value.minute);
    await prefs.setInt('config_endTime_hour',   endTime.value.hour);
    await prefs.setInt('config_endTime_min',    endTime.value.minute);

    Get.snackbar('', 'System Configuration Saved Successfully!',
        backgroundColor: const Color(0xFF0D47A1),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12));
  }
}
