// lib/screens/admin/views/admin_reports_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_reports_controller.dart';

class AdminReportsView extends StatelessWidget {
  const AdminReportsView({super.key});

  static const _blue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminReportsController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Reports', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Daily ──────────────────────────────────────────
          _ReportCard(
            title: 'Daily Attendance Report',
            description:
                'Download detailed daily attendance with check-in and check-out time.',
            icon: LucideIcons.calendarDays,
            extra: Obx(() => OutlinedButton.icon(
                  onPressed: () => c.pickDailyDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd-MM-yyyy').format(c.dailyDate.value)),
                )),
            isLoading: c.isDailyExporting,
            onDownload: c.exportDaily,
          ),

          // ── Monthly ────────────────────────────────────────
          _ReportCard(
            title: 'Monthly Attendance Report',
            description:
                'Full month grid with per-day status and totals for every employee.',
            icon: LucideIcons.calendarRange,
            extra: Obx(() => Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: c.monthlyMonth.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        for (int m = 1; m <= 12; m++)
                          DropdownMenuItem(
                            value: m,
                            child: Text(
                                AdminReportsController.monthNames[m - 1]),
                          ),
                      ],
                      onChanged: (m) => m == null ? null : c.setMonth(m),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: c.monthlyYear.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        for (final y in c.selectableYears)
                          DropdownMenuItem(value: y, child: Text('$y')),
                      ],
                      onChanged: (y) => y == null ? null : c.setYear(y),
                    ),
                  ),
                ])),
            isLoading: c.isMonthlyExporting,
            onDownload: c.exportMonthly,
          ),
        ]),
      ),
    );
  }
}

// ─── Report Card ───────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Widget extra;
  final RxBool isLoading;
  final VoidCallback onDownload;

  static const _blue      = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.extra,
    required this.isLoading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: _lightBlue,
                child: Icon(icon, color: _blue)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _blue))),
          ]),
          const SizedBox(height: 8),
          Text(description,
              style:
                  const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          extra,
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() => ElevatedButton.icon(
                  onPressed: isLoading.value ? null : onDownload,
                  icon: isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download, color: Colors.white),
                  label: const Text('Download',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                )),
          ),
        ]),
      ),
    );
  }
}
