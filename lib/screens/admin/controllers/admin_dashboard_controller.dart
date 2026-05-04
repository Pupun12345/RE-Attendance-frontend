// lib/screens/admin/controllers/admin_dashboard_controller.dart

import 'package:get/get.dart';

class AdminDashboardController extends GetxController {
  final selectedIndex = 0.obs;
  void changeTab(int i) => selectedIndex.value = i;
}
