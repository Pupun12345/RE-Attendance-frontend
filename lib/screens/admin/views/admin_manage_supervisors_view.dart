// lib/screens/admin/views/admin_manage_supervisors_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_manage_users_local_controller.dart';

class AdminManageSupervisorsView extends StatelessWidget {
  const AdminManageSupervisorsView({super.key});

  static const _blue = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminManageSupervisorsController());

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
        title: const Text('Manage Supervisors',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: c.supervisors.length,
            itemBuilder: (_, i) {
              final s = c.supervisors[i];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _lightBlue,
                    backgroundImage:
                        s.image != null ? FileImage(s.image!) : null,
                    child: s.image == null
                        ? Text(s.name[0],
                            style: const TextStyle(
                                color: _blue, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(s.name,
                      style: const TextStyle(
                          color: _blue, fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.email}\nPhone: ${s.phone}',
                      style: const TextStyle(height: 1.4)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(LucideIcons.edit,
                            color: Colors.orange),
                        onPressed: () => c.showEditDialog(i)),
                    IconButton(
                        icon: const Icon(LucideIcons.trash2,
                            color: Colors.redAccent),
                        onPressed: () => c.deleteSupervisor(i)),
                  ]),
                ),
              );
            },
          )),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _blue,
        onPressed: c.showAddDialog,
        label: const Text('Add Supervisor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
