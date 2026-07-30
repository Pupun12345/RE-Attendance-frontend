// lib/screens/admin/views/admin_complaint_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_complaint_controller.dart';

class AdminComplaintView extends StatelessWidget {
  const AdminComplaintView({super.key});

  static const _blue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminComplaintController());

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
        title: const Text('Complaints',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }
        if (c.complaints.isEmpty) {
          return const Center(
              child: Text('No complaints in last 7 days.',
                  style: TextStyle(color: Colors.black54, fontSize: 15)));
        }
        return RefreshIndicator(
          onRefresh: c.fetchComplaints,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (c.hasMore &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 300) {
                c.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: c.pagedComplaints.length + (c.hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == c.pagedComplaints.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: _blue),
                      ),
                    ),
                  );
                }
                return _ComplaintCard(c.pagedComplaints[i]);
              },
            ),
          ),
        );
      }),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final AdminComplaint complaint;
  const _ComplaintCard(this.complaint);

  static const _blue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(complaint.title,
              style: const TextStyle(
                  color: _blue, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(complaint.description),
          const Divider(height: 20),

          if (complaint.isByProxy) ...[
            Row(children: [
              Icon(LucideIcons.user, size: 14, color: Colors.blue[800]),
              const SizedBox(width: 6),
              Text(
                'Affected: ${complaint.user.name} (${complaint.user.userId})',
                style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'Submitted by: ${complaint.submittedBy.name} (Supervisor)',
              style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ] else
            Text('${complaint.user.name} (${complaint.user.userId})',
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),

          Align(
            alignment: Alignment.centerRight,
            child: Text(complaint.formattedDate,
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}
