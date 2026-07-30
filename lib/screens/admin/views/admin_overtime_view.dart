// lib/screens/admin/views/admin_overtime_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/models/overtime_model.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_overtime_controller.dart';

class AdminOvertimeView extends StatelessWidget {
  const AdminOvertimeView({super.key});

  static const _blue      = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminOvertimeController());

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
        title: const Text('Overtime View',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: c.tabController,
          indicatorColor: _blue,
          labelColor: _blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Obx(() => _tabItem(LucideIcons.clock3,    'Pending',  c.pendingList.length)),
            Obx(() => _tabItem(LucideIcons.checkCircle,'Approved', c.approvedList.length)),
            Obx(() => _tabItem(LucideIcons.xCircle,   'Rejected', c.rejectedList.length)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Obx(() {
            if (c.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: _blue));
            }
            return TabBarView(
              controller: c.tabController,
              children: [
                Obx(() => _OvertimeList(
                    records: c.pagedPending,
                    isPending: true,
                    controller: c,
                    hasMore: c.pendingHasMore,
                    onLoadMore: c.loadMorePending,
                    emptyMsg: 'No pending overtime requests.')),
                Obx(() => _OvertimeList(
                    records: c.pagedApproved,
                    isPending: false,
                    controller: c,
                    hasMore: c.approvedHasMore,
                    onLoadMore: c.loadMoreApproved,
                    emptyMsg: 'No approved overtime records.')),
                Obx(() => _OvertimeList(
                    records: c.pagedRejected,
                    isPending: false,
                    controller: c,
                    hasMore: c.rejectedHasMore,
                    onLoadMore: c.loadMoreRejected,
                    emptyMsg: 'No rejected overtime records.')),
              ],
            );
          }),
          Obx(() {
            if (!c.isActionLoading.value) return const SizedBox.shrink();
            return Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(
                child: CircularProgressIndicator(color: _blue),
              ),
            );
          }),
        ],
      ),
    );
  }

  Tab _tabItem(IconData icon, String label, int count) => Tab(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
              child: Text('$label ($count)',
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );
}

// ─── List ──────────────────────────────────────────────────────────────────

class _OvertimeList extends StatelessWidget {
  final List<OvertimeRecord> records;
  final bool isPending;
  final AdminOvertimeController controller;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final String emptyMsg;

  const _OvertimeList({
    required this.records,
    required this.isPending,
    required this.controller,
    required this.hasMore,
    required this.onLoadMore,
    required this.emptyMsg,
  });

  static const _blue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
          child: Text(emptyMsg,
              style: const TextStyle(fontSize: 16, color: Colors.black54)));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 300) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length + (hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == records.length) {
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
          return isPending
              ? _PendingCard(record: records[i], c: controller)
              : _HistoryCard(record: records[i]);
        },
      ),
    );
  }
}

// ─── Pending Card ──────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final OvertimeRecord record;
  final AdminOvertimeController c;
  const _PendingCard({required this.record, required this.c});

  static const _blue      = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(
                backgroundColor: _lightBlue,
                child: Icon(LucideIcons.user, color: _blue)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(record.user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _blue)),
                Text('Role: ${record.user.role}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ]),
            ),
          ]),
          const Divider(),
          Text('Date: ${DateFormat("MMM dd, yyyy").format(record.date)}'),
          Text('Hours: ${record.hours.toStringAsFixed(1)} hrs'),
          Text('Reason: ${record.reason}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton(
              onPressed: c.isActionLoading.value ? null : () => c.handleAction(record, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: c.isActionLoading.value ? null : () => c.handleAction(record, false),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Reject',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── History Card ──────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final OvertimeRecord record;
  const _HistoryCard({required this.record});

  static const _blue      = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final approved = record.status == 'approved';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _lightBlue,
          child: Icon(approved ? LucideIcons.check : LucideIcons.x,
              color: approved ? Colors.green : Colors.red),
        ),
        title: Text(record.user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(color: _blue, fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Date: ${DateFormat("MMM dd, yyyy").format(record.date)}\nReason: ${record.reason}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text('${record.hours} hrs',
            style: TextStyle(
                color: approved ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
