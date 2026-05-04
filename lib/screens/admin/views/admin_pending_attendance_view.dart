// lib/screens/admin/views/admin_pending_attendance_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/models/pending_attendance_model.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_pending_attendance_controller.dart';

class AdminPendingAttendanceView extends StatelessWidget {
  const AdminPendingAttendanceView({super.key});

  static const _blue      = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminPendingAttendanceController());

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
        title: const Text('Pending Attendance',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }
        return RefreshIndicator(
          onRefresh: c.fetchRequests,
          child: Column(children: [
            const SizedBox(height: 8),

            // ── Category Selector ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: PendingCategory.values.map((cat) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Obx(() {
                        final selected = c.selectedCategory.value == cat;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => c.selectedCategory.value = cat,
                          child: Card(
                            color: selected ? _blue : Colors.white,
                            elevation: selected ? 3 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: selected
                                      ? _blue
                                      : Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(c.iconFor(cat),
                                        size: 18,
                                        color: selected
                                            ? Colors.white
                                            : _blue),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '${c.labelFor(cat)} (${c.countFor(cat)})',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: selected
                                              ? Colors.white
                                              : _blue,
                                        ),
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // ── Filtered List ─────────────────────────────
            Expanded(
              child: Obx(() {
                final list = c.filtered;
                if (list.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height / 4),
                      Center(
                        child: Text(
                          'No pending ${c.labelFor(c.selectedCategory.value)} attendance.',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 16),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _RequestCard(
                      staff: list[i], c: c),
                );
              }),
            ),
          ]),
        );
      }),
    );
  }
}

// ─── Request Card ──────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final PendingAttendance staff;
  final AdminPendingAttendanceController c;
  const _RequestCard({required this.staff, required this.c});

  static const _blue      = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    ImageProvider img = const AssetImage('assets/images/profile.png');
    if (staff.user.profileImageUrl != null &&
        staff.user.profileImageUrl!.isNotEmpty) {
      img = NetworkImage(staff.user.profileImageUrl!);
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: _lightBlue, backgroundImage: img),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.user.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _blue,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                        'Time: ${DateFormat("hh:mm a").format(staff.checkInTime)}',
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 14)),
                    Text(
                        'Date: ${DateFormat("MMM dd, yyyy").format(staff.checkInTime)}',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                  ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => c.handleAction(staff, true),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => c.handleAction(staff, false),
            ),
          ]),
        ]),
      ),
    );
  }
}
