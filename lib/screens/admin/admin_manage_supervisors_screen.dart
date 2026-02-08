import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminManageSupervisorsScreen extends StatefulWidget {
  const AdminManageSupervisorsScreen({super.key});

  @override
  State<AdminManageSupervisorsScreen> createState() =>
      _AdminManageSupervisorsScreenState();
}

class _AdminManageSupervisorsScreenState
    extends State<AdminManageSupervisorsScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final ImagePicker _picker = ImagePicker();

  // 🔹 Dummy Supervisors Data
  List<Map<String, dynamic>> supervisors = [
    {"name": "Rahul Verma", "email": "rahul@company.com", "phone": "9876543210", "image": null},
    {"name": "Sneha Patel", "email": "sneha@company.com", "phone": "9998887776", "image": null},
    {"name": "Vikram Das", "email": "vikram@company.com", "phone": "9080706050", "image": null},
  ];

  // 📸 Pick Image Helper
  Future<File?> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return image != null ? File(image.path) : null;
  }

  // 🔹 Edit Supervisor
  void _editSupervisor(int index) {
    final TextEditingController nameController =
    TextEditingController(text: supervisors[index]["name"]);
    final TextEditingController emailController =
    TextEditingController(text: supervisors[index]["email"]);
    final TextEditingController phoneController =
    TextEditingController(text: supervisors[index]["phone"]);
    File? selectedImage = supervisors[index]["image"];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: const Text("Edit Supervisor Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Image upload button
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
                      style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
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

                // 🔹 Email Field
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
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
                  supervisors[index]["name"] = nameController.text;
                  supervisors[index]["email"] = emailController.text;
                  supervisors[index]["phone"] = phoneController.text;
                  supervisors[index]["image"] = selectedImage;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                    Text("${supervisors[index]['name']} updated successfully!"),
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

  // 🔹 Delete Supervisor
  void _deleteSupervisor(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete ${supervisors[index]['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() => supervisors.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Supervisor deleted successfully!"), backgroundColor: Colors.redAccent),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // 🔹 Add Supervisor Dialog
  void _addSupervisor() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: const Text("Add New Supervisor"),
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
                      style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
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
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    emailController.text.trim().isNotEmpty &&
                    phoneController.text.trim().isNotEmpty) {
                  setState(() {
                    supervisors.add({
                      "name": nameController.text,
                      "email": emailController.text,
                      "phone": phoneController.text,
                      "image": selectedImage,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${nameController.text} added successfully!"),
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
          "Manage Supervisors",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
      ),

      // 🔹 Supervisor List
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: supervisors.length,
        itemBuilder: (context, index) {
          final s = supervisors[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: lightBlue,
                backgroundImage: s["image"] != null ? FileImage(s["image"]) : null,
                child: s["image"] == null
                    ? Text(
                  s["name"]![0],
                  style: TextStyle(
                      color: primaryBlue, fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              title: Text(s["name"]!,
                  style:
                  TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
              subtitle: Text("${s["email"]}\nPhone: ${s["phone"]}",
                  style: const TextStyle(height: 1.4)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: Icon(LucideIcons.edit, color: Colors.orange),
                    onPressed: () => _editSupervisor(index)),
                IconButton(
                    icon: Icon(LucideIcons.trash2, color: Colors.redAccent),
                    onPressed: () => _deleteSupervisor(index)),
              ]),
            ),
          );
        },
      ),

      // 🔹 Add Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: _addSupervisor,
        label: const Text(
          "Add Supervisor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}