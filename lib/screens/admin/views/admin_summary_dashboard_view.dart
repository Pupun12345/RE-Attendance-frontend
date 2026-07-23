// lib/screens/admin/views/admin_summary_dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_summary_dashboard_controller.dart';
import 'package:smartcare_app/screens/admin/views/admin_pending_attendance_view.dart';

class AdminSummaryDashboardView extends StatelessWidget {
  const AdminSummaryDashboardView({super.key});

  static const _blue      = Color(0xFF0D47A1);
  static const _bg        = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminSummaryDashboardController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Dashboard Summary',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(LucideIcons.bell, color: Colors.white),
              onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }
        return RefreshIndicator(
          onRefresh: c.fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Top row
              Row(children: [
                Expanded(child: _InfoCard(
                    icon: LucideIcons.userCog,
                    title: 'Total Supervisors',
                    value: c.totalSupervisors.value)),
                const SizedBox(width: 12),
                Expanded(child: _InfoCard(
                    icon: LucideIcons.users,
                    title: 'Total Workers',
                    value: c.totalWorkers.value)),
              ]),
              const SizedBox(height: 12),

              // Management
              _InfoCard(
                  icon: LucideIcons.briefcase,
                  title: 'Total Management',
                  value: c.totalManagement.value),
              const SizedBox(height: 16),

              // Attendance Summary
              _AttendanceCard(
                  present: c.presentToday.value,
                  absent: c.absentToday.value),
              const SizedBox(height: 16),

              // Pending Attendance
              _PendingCard(),
            ]),
          ),
        );
      }),
    );
  }
}

// ─── Info Card ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;

  static const _blue      = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  const _InfoCard(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: _lightBlue,
              child: Icon(icon, color: _blue, size: 22)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value.toString(),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _blue)),
                Text(title,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13)),
              ])),
        ]),
      ),
    );
  }
}

// ─── Attendance Card ───────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final int present, absent;

  static const _blue = Color(0xFF0D47A1);

  const _AttendanceCard({required this.present, required this.absent});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Today's Attendance",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: _blue, fontSize: 16)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _StatItem(
                icon: LucideIcons.checkCircle,
                color: Colors.green,
                label: 'Present',
                value: present),
            _StatItem(
                icon: LucideIcons.xCircle,
                color: Colors.redAccent,
                label: 'Absent',
                value: absent),
          ]),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;

  static const _blue = Color(0xFF0D47A1);

  const _StatItem(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value.toString(),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _blue)),
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ]),
    ]);
  }
}

// ─── Pending Card ──────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  static const _blue      = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const AdminPendingAttendanceView()),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        color: Colors.white,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(children: [
            const CircleAvatar(
                radius: 22,
                backgroundColor: _lightBlue,
                child: Icon(LucideIcons.clock, color: _blue, size: 24)),
            const SizedBox(width: 14),
            const Expanded(
                child: Text('Pending Attendance',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _blue))),
            Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.grey.shade500),
          ]),
        ),
      ),
    );
  }
}
