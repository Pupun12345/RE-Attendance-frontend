// lib/screens/admin/views/submit_overtime_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/submit_overtime_controller.dart';

class SubmitOvertimeView extends StatelessWidget {
  const SubmitOvertimeView({super.key});

  static const _blue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SubmitOvertimeController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _blue),
          onPressed: () => Get.back(),
        ),
        title: const Text('Submit Overtime',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: c.formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Submit a request for overtime approval.',
                style: TextStyle(color: Colors.grey[700], fontSize: 15)),
            const SizedBox(height: 24),

            // ── Date Picker ─────────────────────────────
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Date of Overtime',
                  style: TextStyle(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(() => GestureDetector(
                    onTap: () => c.pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(children: [
                        const Icon(LucideIcons.calendar,
                            color: _blue, size: 20),
                        const SizedBox(width: 12),
                        Text(c.formattedDate,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87)),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.grey),
                      ]),
                    ),
                  )),
            ]),
            const SizedBox(height: 16),

            // ── Hours ───────────────────────────────────
            TextFormField(
              controller: c.hoursCtrl,
              keyboardType: TextInputType.number,
              validator: c.validateHours,
              decoration: InputDecoration(
                labelText: 'Hours Worked',
                hintText: 'e.g., 2.5',
                labelStyle: const TextStyle(color: _blue),
                prefixIcon:
                    const Icon(LucideIcons.clock, color: _blue, size: 20),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _blue, width: 2),
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // ── Reason ──────────────────────────────────
            TextFormField(
              controller: c.reasonCtrl,
              keyboardType: TextInputType.multiline,
              maxLines: 4,
              validator: c.validateReason,
              decoration: InputDecoration(
                labelText: 'Reason for Overtime',
                hintText: 'Describe the task...',
                labelStyle: const TextStyle(color: _blue),
                prefixIcon: const Icon(LucideIcons.clipboardList,
                    color: _blue, size: 20),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _blue, width: 2),
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // ── Submit Button ───────────────────────────
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        c.isSubmitting.value ? null : c.submitOvertime,
                    icon: c.isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(LucideIcons.send, color: Colors.white),
                    label: Text(
                      c.isSubmitting.value
                          ? 'Submitting...'
                          : 'Submit Request',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )),
          ]),
        ),
      ),
    );
  }
}
