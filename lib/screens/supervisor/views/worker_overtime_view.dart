// lib/screens/supervisor/views/worker_overtime_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartcare_app/screens/supervisor/controllers/worker_overtime_controller.dart';

class WorkerOvertimeView extends StatelessWidget {
  final String name;
  final String userId;
  final String dbId;

  const WorkerOvertimeView({super.key, required this.name, required this.userId, required this.dbId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WorkerOvertimeController());
    controller.init(name: name, userId: userId, dbId: dbId);
    const themeBlue = Color(0xFF0B3B8C);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        title: const Text('Overtime Submission',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => _InfoRow(label: 'Date & Time', icon: Icons.calendar_today_outlined, text: controller.dateTimeText.value)),
            _InfoRow(label: 'Worker Name', icon: Icons.person_outline, text: name),
            _InfoRow(label: 'Worker ID', icon: Icons.badge_outlined, text: userId),
            const SizedBox(height: 18),

            const Text('Hours Worked', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.hoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 2.5',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),

            const Text('Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for overtime...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 28),

            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isSubmitting.value ? null : controller.submitOvertime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: controller.isSubmitting.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Overtime',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, text;
  final IconData icon;
  const _InfoRow({required this.label, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87))),
        ]),
      ),
      const SizedBox(height: 18),
    ]);
  }
}