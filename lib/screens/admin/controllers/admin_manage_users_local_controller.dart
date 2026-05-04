// lib/screens/admin/controllers/admin_manage_users_local_controller.dart
//
// Covers all 3 local-only screens:
//   AdminManageManagementStaffController
//   AdminManageSupervisorsController
//   AdminManageWorkersController
//
// Note: These 3 original screens used dummy in-memory data + ImagePicker (no API).
// GetX pattern keeps the same logic — RxList holds the data, dialogs via Get.dialog.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// ─── Generic Staff Entry ───────────────────────────────────────────────────

class StaffEntry {
  String name;
  String? email;
  String? phone;
  File? image;

  StaffEntry({required this.name, this.email, this.phone, this.image});
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. Manage Management Staff Controller
// ═══════════════════════════════════════════════════════════════════════════

class AdminManageManagementStaffController extends GetxController {
  final staff = <StaffEntry>[
    StaffEntry(name: 'Amit Sharma',  email: 'amit@company.com',  phone: '9876543210'),
    StaffEntry(name: 'Priya Singh',  email: 'priya@company.com', phone: '9876501234'),
    StaffEntry(name: 'Ravi Kumar',   email: 'ravi@company.com',  phone: '9123456780'),
  ].obs;

  final _picker = ImagePicker();

  Future<File?> pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return x != null ? File(x.path) : null;
  }

  void deleteStaff(int index) {
    Get.dialog(AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Delete ${staff[index].name}?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            staff.removeAt(index);
            Get.back();
            _ok('Staff deleted successfully!');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void showAddDialog() => _showFormDialog(null);
  void showEditDialog(int index) => _showFormDialog(index);

  void _showFormDialog(int? editIndex) {
    final existing = editIndex != null ? staff[editIndex] : null;
    final nameCtrl  = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final imgObs    = Rxn<File>(existing?.image);

    Get.dialog(StatefulBuilder(builder: (_, setS) {
      return AlertDialog(
        title: Text(editIndex == null ? 'Add Management Staff' : 'Edit Staff Details'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Obx(() => GestureDetector(
              onTap: () async {
                final img = await pickImage();
                if (img != null) imgObs.value = img;
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFE3F2FD),
                backgroundImage: imgObs.value != null ? FileImage(imgObs.value!) : null,
                child: imgObs.value == null
                    ? const Icon(Icons.camera_alt, color: Color(0xFF0D47A1), size: 28)
                    : null,
              ),
            )),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
              if (editIndex == null) {
                staff.add(StaffEntry(
                  name: nameCtrl.text, email: emailCtrl.text,
                  phone: phoneCtrl.text, image: imgObs.value,
                ));
                _ok('${nameCtrl.text} added successfully!');
              } else {
                staff[editIndex].name  = nameCtrl.text;
                staff[editIndex].email = emailCtrl.text;
                staff[editIndex].phone = phoneCtrl.text;
                staff[editIndex].image = imgObs.value;
                staff.refresh();
                _ok('${nameCtrl.text} updated!');
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
            child: Text(editIndex == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      );
    }));
  }

  void _ok(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.green, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. Manage Supervisors Controller
// ═══════════════════════════════════════════════════════════════════════════

class AdminManageSupervisorsController extends GetxController {
  final supervisors = <StaffEntry>[
    StaffEntry(name: 'Rahul Verma',  email: 'rahul@company.com', phone: '9876543210'),
    StaffEntry(name: 'Sneha Patel',  email: 'sneha@company.com', phone: '9998887776'),
    StaffEntry(name: 'Vikram Das',   email: 'vikram@company.com', phone: '9080706050'),
  ].obs;

  final _picker = ImagePicker();

  Future<File?> pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return x != null ? File(x.path) : null;
  }

  void deleteSupervisor(int index) {
    Get.dialog(AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Delete ${supervisors[index].name}?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            supervisors.removeAt(index);
            Get.back();
            _ok('Supervisor deleted successfully!');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void showAddDialog() => _showFormDialog(null);
  void showEditDialog(int index) => _showFormDialog(index);

  void _showFormDialog(int? editIndex) {
    final existing = editIndex != null ? supervisors[editIndex] : null;
    final nameCtrl  = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final imgObs    = Rxn<File>(existing?.image);

    Get.dialog(StatefulBuilder(builder: (_, __) {
      return AlertDialog(
        title: Text(editIndex == null ? 'Add New Supervisor' : 'Edit Supervisor Details'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Obx(() => GestureDetector(
              onTap: () async {
                final img = await pickImage();
                if (img != null) imgObs.value = img;
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFE3F2FD),
                backgroundImage: imgObs.value != null ? FileImage(imgObs.value!) : null,
                child: imgObs.value == null
                    ? const Icon(Icons.camera_alt, color: Color(0xFF0D47A1), size: 28)
                    : null,
              ),
            )),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final img = await pickImage();
                if (img != null) imgObs.value = img;
              },
              child: const Text('Upload Photo',
                  style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
              if (editIndex == null) {
                supervisors.add(StaffEntry(
                  name: nameCtrl.text, email: emailCtrl.text,
                  phone: phoneCtrl.text, image: imgObs.value,
                ));
                _ok('${nameCtrl.text} added successfully!');
              } else {
                supervisors[editIndex].name  = nameCtrl.text;
                supervisors[editIndex].email = emailCtrl.text;
                supervisors[editIndex].phone = phoneCtrl.text;
                supervisors[editIndex].image = imgObs.value;
                supervisors.refresh();
                _ok('${nameCtrl.text} updated successfully!');
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
            child: Text(editIndex == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      );
    }));
  }

  void _ok(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.green, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. Manage Workers Controller
// ═══════════════════════════════════════════════════════════════════════════

class AdminManageWorkersController extends GetxController {
  final workers = <StaffEntry>[
    StaffEntry(name: 'Ramesh Kumar', phone: '9876543210'),
    StaffEntry(name: 'Suresh Yadav', phone: '9090909090'),
    StaffEntry(name: 'Anita Sharma', phone: '9911223344'),
    StaffEntry(name: 'Vivek Rao',    phone: '9988776655'),
  ].obs;

  final _picker = ImagePicker();

  Future<File?> pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return x != null ? File(x.path) : null;
  }

  void deleteWorker(int index) {
    Get.dialog(AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Delete ${workers[index].name}?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            workers.removeAt(index);
            Get.back();
            _ok('Worker deleted successfully!');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void showAddDialog() => _showFormDialog(null);
  void showEditDialog(int index) => _showFormDialog(index);

  void _showFormDialog(int? editIndex) {
    final existing = editIndex != null ? workers[editIndex] : null;
    final nameCtrl  = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final imgObs    = Rxn<File>(existing?.image);

    Get.dialog(StatefulBuilder(builder: (_, __) {
      return AlertDialog(
        title: Text(editIndex == null ? 'Add New Worker' : 'Edit Worker Details'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Obx(() => GestureDetector(
              onTap: () async {
                final img = await pickImage();
                if (img != null) imgObs.value = img;
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFE3F2FD),
                backgroundImage: imgObs.value != null ? FileImage(imgObs.value!) : null,
                child: imgObs.value == null
                    ? const Icon(Icons.camera_alt, color: Color(0xFF0D47A1), size: 28)
                    : null,
              ),
            )),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final img = await pickImage();
                if (img != null) imgObs.value = img;
              },
              child: const Text('Upload Photo',
                  style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
              if (editIndex == null) {
                workers.add(StaffEntry(
                    name: nameCtrl.text, phone: phoneCtrl.text, image: imgObs.value));
                _ok('${nameCtrl.text} added successfully!');
              } else {
                workers[editIndex].name  = nameCtrl.text;
                workers[editIndex].phone = phoneCtrl.text;
                workers[editIndex].image = imgObs.value;
                workers.refresh();
                _ok('${nameCtrl.text} updated successfully!');
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
            child: Text(editIndex == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      );
    }));
  }

  void _ok(String msg) => Get.snackbar('', msg,
      backgroundColor: Colors.green, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
}
