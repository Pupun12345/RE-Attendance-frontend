// lib/screens/admin/views/admin_manage_workers_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_manage_users_local_controller.dart';

class AdminManageWorkersView extends StatelessWidget {
  const AdminManageWorkersView({super.key});

  static const _blue = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminManageWorkersController());

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
        title: const Text('Manage Workers',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: c.workers.length,
            itemBuilder: (_, i) {
              final w = c.workers[i];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _lightBlue,
                    backgroundImage:
                        w.image != null ? FileImage(w.image!) : null,
                    child: w.image == null
                        ? Text(w.name[0],
                            style: const TextStyle(
                                color: _blue, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(w.name,
                      style: const TextStyle(
                          color: _blue, fontWeight: FontWeight.bold)),
                  subtitle: Text('Phone: ${w.phone}',
                      style: const TextStyle(height: 1.4)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(LucideIcons.edit,
                            color: Colors.orange),
                        onPressed: () => c.showEditDialog(i)),
                    IconButton(
                        icon: const Icon(LucideIcons.trash2,
                            color: Colors.redAccent),
                        onPressed: () => c.deleteWorker(i)),
                  ]),
                ),
              );
            },
          )),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _blue,
        onPressed: c.showAddDialog,
        label: const Text('Add Worker',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
