// lib/screens/supervisor/views/worker_complaint_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartcare_app/screens/supervisor/controllers/worker_complaint_controller.dart';

class WorkerComplaintView extends StatelessWidget {
  final String name, userId, dbId;
  const WorkerComplaintView({super.key, required this.name, required this.userId, required this.dbId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WorkerComplaintController());
    controller.init(name: name, userId: userId, dbId: dbId);
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
        title: const Text('Submit Complaint',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: themeBlue.withOpacity(0.08),
                  child: Icon(Icons.person, color: themeBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('ID: $userId', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ])),
              ]),
            ),

            const Text('Complaint Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.titleController,
              decoration: InputDecoration(
                hintText: 'Enter title...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your issue...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 18),

            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.pickFromCamera,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.pickFromGallery,
                  icon: Icon(Icons.upload, color: themeBlue),
                  label: Text('Upload', style: TextStyle(color: themeBlue)),
                ),
              ),
            ]),

            Obx(() => controller.selectedImage.value != null
                ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Image selected: ${controller.selectedImage.value!.path.split('/').last}',
                style: const TextStyle(fontSize: 12),
              ),
            )
                : const SizedBox.shrink()),

            const SizedBox(height: 24),

            Obx(() => SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: controller.isSubmitting.value ? null : controller.submitComplaint,
                style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
                child: controller.isSubmitting.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Complaint',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}