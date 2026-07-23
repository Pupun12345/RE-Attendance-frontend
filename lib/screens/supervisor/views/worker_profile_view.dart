// lib/screens/supervisor/views/worker_profile_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartcare_app/screens/supervisor/views/worker_checkin_view.dart';
import 'package:smartcare_app/screens/supervisor/views/worker_checkout_view.dart';
import 'package:smartcare_app/screens/supervisor/views/worker_complaint_view.dart';
import 'package:smartcare_app/screens/supervisor/views/worker_overtime_view.dart';

class WorkerProfileView extends StatelessWidget {
  final String name, userId, dbId;
  const WorkerProfileView({super.key, required this.name, required this.userId, required this.dbId});

  @override
  Widget build(BuildContext context) {
    const themeBlue = Color(0xFF0B3B8C);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Worker Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          // Check-In / Check-Out card
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Worker Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: themeBlue)),
            const SizedBox(height: 12),
            Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: themeBlue.withValues(alpha: 0.08),
                child: const Icon(Icons.person, color: themeBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(userId, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _Btn(icon: Icons.login_outlined, label: 'Check-In', themeBlue: themeBlue,
                  onTap: () => Get.to(() => WorkerCheckInView(workerName: name, workerId: userId, workerDbId: dbId)))),
              const SizedBox(width: 12),
              Expanded(child: _Btn(icon: Icons.logout_outlined, label: 'Check-Out', themeBlue: themeBlue,
                  onTap: () => Get.to(() => WorkerCheckOutView(workerName: name, workerId: userId, workerDbId: dbId)))),
            ]),
          ])),

          const SizedBox(height: 16),

          // Complaint card
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Submit Complaint',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: themeBlue)),
            const SizedBox(height: 8),
            const Text('If the worker has any issue related to work, safety or attendance, you can submit a complaint on their behalf.',
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity,
                child: _Btn(icon: Icons.report_problem_outlined, label: 'Submit Complaint', themeBlue: themeBlue,
                    onTap: () => Get.to(() => WorkerComplaintView(name: name, userId: userId, dbId: dbId)))),
          ])),

          const SizedBox(height: 16),

          // Overtime card
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Overtime Submission',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 6),
            const Text('Submit your overtime requests quickly and easily.',
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity,
                child: _Btn(icon: Icons.play_arrow_rounded, label: 'Overtime Submit', themeBlue: themeBlue,
                    onTap: () => Get.to(() => WorkerOvertimeView(name: name, userId: userId, dbId: dbId)))),
          ])),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color themeBlue;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.label, required this.themeBlue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}