// lib/screens/supervisor/views/supervisor_dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartcare_app/screens/shared/holiday_calendar/holiday_calendar_view.dart';
import 'package:smartcare_app/screens/shared/holiday_calendar_screen.dart';
import 'package:smartcare_app/screens/shared/overtime_submission/overtime_submission_view.dart';
import 'package:smartcare_app/screens/shared/overtime_submission_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkin/selfie_checkin_view.dart';
import 'package:smartcare_app/screens/shared/selfie_checkin_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkout/selfie_checkout_view.dart';
import 'package:smartcare_app/screens/shared/selfie_checkout_screen.dart';
import 'package:smartcare_app/screens/shared/submit_complaint/submit_complaint_view.dart';
import 'package:smartcare_app/screens/shared/submit_complaint_screen.dart';
import 'package:smartcare_app/screens/supervisor/controllers/supervisor_dashboard_controller.dart';
import 'package:smartcare_app/screens/supervisor/views/attendance_detail_view.dart';
import 'package:smartcare_app/screens/supervisor/views/workers_view.dart';

class SupervisorDashboardView extends StatelessWidget {
  const SupervisorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SupervisorDashboardController());
    const themeBlue = Color(0xFF0B3B8C);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAccessPopup(c, themeBlue);
    });

    return Obx(() {
      if (c.isLoadingProfile.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final List<String> titles = [
        'Supervisor Dashboard', 'Attendance Detail', 'Submit Complaint', 'Workers List', 'My Profile',
      ];
      final hideAppBar = c.selectedIndex.value == 1 || c.selectedIndex.value == 2 || c.selectedIndex.value == 3;

      return Scaffold(
        backgroundColor: const Color(0xFFF7F7FB),
        appBar: hideAppBar
            ? null
            : AppBar(
          title: Text(titles[c.selectedIndex.value],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: themeBlue)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
        ),
        body: IndexedStack(
          index: c.selectedIndex.value,
          children: [
            _HomeTab(controller: c, themeBlue: themeBlue),
            const AttendanceDetailView(),
            const SubmitComplaintView(),
            WorkersView(),
            _ProfileTab(controller: c, themeBlue: themeBlue),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: c.selectedIndex.value,
          onTap: c.changeTab,
          selectedItemColor: themeBlue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.report_gmailerrorred_outlined), label: 'Complaint'),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Workers'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      );
    });
  }

  void _showAccessPopup(SupervisorDashboardController c, Color themeBlue) {
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('User Data Access',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'To enable field tracking, please allow camera and location access during check-in and check-out.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              CheckboxListTile(
                value: c.allowCamera.value,
                onChanged: (val) => c.allowCamera.value = val ?? false,
                title: const Text('Allow Camera'),
                secondary: const Icon(Icons.camera_alt),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: c.allowLocation.value,
                onChanged: (val) => c.allowLocation.value = val ?? false,
                title: const Text('Allow Location'),
                secondary: const Icon(Icons.location_on),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: c.allowContact.value,
                onChanged: (val) => c.allowContact.value = val ?? false,
                title: const Text('Allow Contacts'),
                secondary: const Icon(Icons.contacts),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: c.canContinue ? () => Get.back() : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: const Text('Allow', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

// ── Home Tab ────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final SupervisorDashboardController controller;
  final Color themeBlue;
  const _HomeTab({required this.controller, required this.themeBlue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _DashCard(title: 'Self-Attendance', child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage your daily attendance from here',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const SelfieCheckInView()),
                icon: const Icon(Icons.login_outlined),
                label: const Text('Check-In'),
                style: ElevatedButton.styleFrom(backgroundColor: themeBlue, foregroundColor: Colors.white),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const SelfieCheckOutView()),
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Check-Out'),
                style: ElevatedButton.styleFrom(backgroundColor: themeBlue, foregroundColor: Colors.white),
              )),
            ]),
          ],
        )),

        _DashCard(title: 'Worker Attendance Search', child: Column(children: [
          TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Enter worker ID or name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => WorkersView(initialSearchQuery: controller.searchController.text)),
                icon: const Icon(Icons.search),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(backgroundColor: themeBlue, foregroundColor: Colors.white),
              )),
        ])),

        _DashCard(title: 'Overtime Submission', child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit your overtime requests quickly and easily.'),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => const OvertimeSubmissionView()),
                  icon: const Icon(Icons.send),
                  label: const Text('Overtime Submit'),
                  style: ElevatedButton.styleFrom(backgroundColor: themeBlue, foregroundColor: Colors.white),
                )),
          ],
        )),

        _DashCard(title: 'Holiday Calendar', child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Check upcoming holidays assigned by Admin.'),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => const HolidayCalendarView()),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('View Holiday'),
                  style: ElevatedButton.styleFrom(backgroundColor: themeBlue, foregroundColor: Colors.white),
                )),
          ],
        )),
      ]),
    );
  }
}

// ── Profile Tab ─────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final SupervisorDashboardController controller;
  final Color themeBlue;
  const _ProfileTab({required this.controller, required this.themeBlue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 70,
          backgroundColor: themeBlue.withOpacity(0.1),
          backgroundImage: controller.profileImageUrl.value != null
              ? NetworkImage(controller.profileImageUrl.value!)
              : null,
          child: controller.profileImageUrl.value == null
              ? Icon(Icons.person, size: 80, color: themeBlue)
              : null,
        ),
        const SizedBox(height: 20),
        Text(controller.userName.value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeBlue)),
        const SizedBox(height: 8),
        Text(controller.userId.value,
            style: TextStyle(fontSize: 18, color: Colors.grey[700])),
        const SizedBox(height: 20),
        Divider(color: Colors.grey[300]),
        const SizedBox(height: 20),
        _ProfileDetail(icon: Icons.email_outlined, label: 'Email', value: controller.userEmail.value),
        _ProfileDetail(icon: Icons.phone_outlined, label: 'Phone', value: controller.userPhone.value),
        _ProfileDetail(icon: Icons.badge_outlined, label: 'Role', value: controller.capitalizedRole),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Log Out',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ])),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _DashCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileDetail({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    const themeBlue = Color(0xFF0B3B8C);
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          Icon(icon, color: themeBlue, size: 24),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
          ]),
        ]),
      ),
    );
  }
}