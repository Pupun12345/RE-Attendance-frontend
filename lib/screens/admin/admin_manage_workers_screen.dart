import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminManageWorkersScreen extends StatefulWidget {
  const AdminManageWorkersScreen({super.key});

  @override
  State<AdminManageWorkersScreen> createState() =>
      _AdminManageWorkersScreenState();
}

class _AdminManageWorkersScreenState
    extends State<AdminManageWorkersScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final ImagePicker _picker = ImagePicker();

  // 🔹 Dummy Workers Data
  List<Map<String, dynamic>> workers = [
    {"name": "Ramesh Kumar", "phone": "9876543210", "image": null},
    {"name": "Suresh Yadav", "phone": "9090909090", "image": null},
    {"name": "Anita Sharma", "phone": "9911223344", "image": null},
    {"name": "Vivek Rao", "phone": "9988776655", "image": null},
  ];

  // 📸 Pick Image Helper
  Future<File?> _pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return image != null ? File(image.path) : null;
  }

  // 🔹 Edit Worker
  void _editWorker(int index) {
    final TextEditingController nameController =
    TextEditingController(text: workers[index]["name"]);
    final TextEditingController phoneController =
    TextEditingController(text: workers[index]["phone"]);
    File? selectedImage = workers[index]["image"];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: const Text("Edit Worker Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Photo Upload Avatar
                GestureDetector(
                  onTap: () async {
                    final img = await _pickImage();
                    if (img != null) {
                      setModalState(() => selectedImage = img);
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: lightBlue,
                    backgroundImage:
                    selectedImage != null ? FileImage(selectedImage!) : null,
                    child: selectedImage == null
                        ? Icon(LucideIcons.camera, color: primaryBlue, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final img = await _pickImage();
                    if (img != null) {
                      setModalState(() => selectedImage = img);
                    }
                  },
                  child: Text("Upload Photo",
                      style: TextStyle(
                          color: primaryBlue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                // 🔹 Name Field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Phone Field
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  workers[index]["name"] = nameController.text;
                  workers[index]["phone"] = phoneController.text;
                  workers[index]["image"] = selectedImage;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                    Text("${workers[index]['name']} updated successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              child: const Text("Save"),
            ),
          ],
        );
      }),
    );
  }

  // 🔹 Delete Worker
  void _deleteWorker(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content:
        Text("Are you sure you want to delete ${workers[index]['name']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                workers.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Worker deleted successfully!"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // 🔹 Add New Worker
  void _addWorker() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: const Text("Add New Worker"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await _pickImage();
                    if (img != null) {
                      setModalState(() => selectedImage = img);
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: lightBlue,
                    backgroundImage:
                    selectedImage != null ? FileImage(selectedImage!) : null,
                    child: selectedImage == null
                        ? Icon(LucideIcons.camera, color: primaryBlue, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final img = await _pickImage();
                    if (img != null) {
                      setModalState(() => selectedImage = img);
                    }
                  },
                  child: Text("Upload Photo",
                      style: TextStyle(
                          color: primaryBlue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    phoneController.text.trim().isNotEmpty) {
                  setState(() {
                    workers.add({
                      "name": nameController.text,
                      "phone": phoneController.text,
                      "image": selectedImage,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text("${nameController.text} added successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              child: const Text("Add"),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Manage Workers",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // 🔹 Worker List
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: lightBlue,
                backgroundImage: worker["image"] != null
                    ? FileImage(worker["image"])
                    : null,
                child: worker["image"] == null
                    ? Text(
                  worker["name"]![0],
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              title: Text(
                worker["name"]!,
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text("Phone: ${worker["phone"]}",
                  style: const TextStyle(height: 1.4)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.edit, color: Colors.orange),
                    onPressed: () => _editWorker(index),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.trash2, color: Colors.redAccent),
                    onPressed: () => _deleteWorker(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // 🔹 Add Worker Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: _addWorker,
        label: const Text(
          "Add Worker",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}