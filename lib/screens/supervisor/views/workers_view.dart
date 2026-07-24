// lib/screens/supervisor/views/workers_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Worker;
import 'package:smartcare_app/screens/supervisor/controllers/workers_controller.dart';
import 'package:smartcare_app/screens/supervisor/views/worker_profile_view.dart';

class WorkersView extends StatelessWidget {
  final String? initialSearchQuery;
  const WorkersView({super.key, this.initialSearchQuery});

  @override
  Widget build(BuildContext context) {
    // permanent: true keeps this controller (and its search TextField's
    // TextEditingController) alive instead of letting GetX auto-dispose it
    // when the route is popped - that auto-dispose could race with an
    // in-flight tap on this screen's TextField during the pop transition
    // and crash with "used after being disposed". Since the controller no
    // longer resets itself on re-entry, explicitly refresh the list here.
    final isFirstBuild = !Get.isRegistered<WorkersController>();
    final controller = Get.put(WorkersController(), permanent: true);
    if (!isFirstBuild) controller.fetchWorkers();
    if (initialSearchQuery != null) controller.setInitialQuery(initialSearchQuery);
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
        title: const Text('Workers',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search worker by name or ID...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMsg.value != null) {
                  return ListView(children: [_WorkerRow(worker: controller.dummyWorker)]);
                }
                if (controller.filteredWorkers.isEmpty) {
                  return Center(
                    child: Text(controller.searchController.text.isEmpty
                        ? 'No workers found.'
                        : 'No workers match your search.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.fetchWorkers,
                  child: ListView.builder(
                    itemCount: controller.filteredWorkers.length,
                    itemBuilder: (_, i) => _WorkerRow(worker: controller.filteredWorkers[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerRow extends StatelessWidget {
  final Worker worker;
  const _WorkerRow({required this.worker});

  @override
  Widget build(BuildContext context) {
    const themeBlue = Color(0xFF0B3B8C);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: worker.profileImageUrl != null ? NetworkImage(worker.profileImageUrl!) : null,
            child: worker.profileImageUrl == null ? const Icon(Icons.person, size: 26) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(worker.userId, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => Get.to(() => WorkerProfileView(
                name: worker.name, userId: worker.userId, dbId: worker.id)),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Take Attendance', maxLines: 1,
                overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}