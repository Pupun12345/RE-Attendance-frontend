// lib/screens/admin/views/admin_dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:smartcare_app/screens/admin/controllers/admin_dashboard_controller.dart';
import 'package:smartcare_app/screens/admin/views/admin_complaint_view.dart';
import 'package:smartcare_app/screens/admin/views/admin_holiday_setup_view.dart';
import 'package:smartcare_app/screens/admin/views/admin_overtime_view.dart';
import 'package:smartcare_app/screens/admin/views/admin_reports_view.dart';
import 'package:smartcare_app/screens/admin/views/admin_settings_view.dart';
import 'package:smartcare_app/screens/admin/views/admin_summary_dashboard_view.dart';
import 'package:smartcare_app/screens/shared/manage_users/manage_users_view.dart';



class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  static const _blue = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminDashboardController());

    return Obx(() {
      final pages = [
        const _HomeTab(blue: _blue, lightBlue: _lightBlue),
        const AdminSummaryDashboardView(),
        const ManageUsersView(),
        const AdminReportsView(),
        const AdminSettingsView(),
      ];

      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: c.selectedIndex.value == 0
            ? AppBar(
                backgroundColor: _blue,
                elevation: 1,
                centerTitle: true,
                title: const Text('Home',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
        body: pages[c.selectedIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: c.selectedIndex.value,
          onTap: c.changeTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _blue,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.users), label: 'Users'),
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.barChart2), label: 'Reports'),
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.settings), label: 'Settings'),
          ],
        ),
      );
    });
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final Color blue, lightBlue;
  const _HomeTab({required this.blue, required this.lightBlue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _DashCard(
          icon: LucideIcons.users,
          title: 'Manage Management Staff',
          subtitle: 'Add, edit, or remove management-level employees.',
          blue: blue, lightBlue: lightBlue,
          onTap: () => Get.to(() => const ManageUsersView(roleFilter: 'management')),
        ),
        _DashCard(
          icon: LucideIcons.userCog,
          title: 'Manage Supervisors',
          subtitle: 'Handle supervisor accounts and assign roles.',
          blue: blue, lightBlue: lightBlue,
          onTap: () => Get.to(() => const ManageUsersView(roleFilter: 'supervisor')),
        ),
        _DashCard(
          icon: LucideIcons.user,
          title: 'Manage Workers',
          subtitle: 'Oversee worker profiles and attendance.',
          blue: blue, lightBlue: lightBlue,
          onTap: () => Get.to(() => const ManageUsersView(roleFilter: 'worker')),
        ),
        _DashCard(
          icon: LucideIcons.clock8,
          title: 'Overtime View',
          subtitle: 'Monitor overtime requests.',
          blue: blue, lightBlue: lightBlue,
          onTap: () => Get.to(() => const AdminOvertimeView()),
        ),
        _DashCard(
          icon: LucideIcons.messageCircle,
          title: 'Complaint View',
          subtitle: 'Review and resolve complaints.',
          blue: blue, lightBlue: lightBlue,
          onTap: () => Get.to(() => const AdminComplaintView()),
        ),
        _DashCard(
          icon: LucideIcons.calendarDays,
          title: 'Set Holidays',
          subtitle: 'Configure holidays.',
          blue: blue, lightBlue: lightBlue,
          onTap: () => Get.to(() => const AdminHolidaySetupView()),
        ),
      ]),
    );
  }
}

class _DashCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color blue, lightBlue;
  final VoidCallback onTap;

  const _DashCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.blue,
    required this.lightBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                radius: 25,
                backgroundColor: lightBlue,
                child: Icon(icon, color: blue, size: 28)),
            const SizedBox(width: 16),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: blue,
                        fontSize: 16))),
          ]),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(subtitle,
                style: const TextStyle(
                    color: Colors.black54, fontSize: 14, height: 1.3)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View Details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}
