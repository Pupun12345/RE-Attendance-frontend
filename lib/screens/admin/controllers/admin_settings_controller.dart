// lib/screens/admin/controllers/admin_settings_controller.dart

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/screens/shared/login/login_view.dart';
import 'package:smartcare_app/screens/shared/login_screen.dart';

class AdminSettingsController extends GetxController {
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(() => const LoginView());
  }
}
