import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminManageManagementStaffScreen extends StatefulWidget {
  const AdminManageManagementStaffScreen({super.key});

  @override
  State<AdminManageManagementStaffScreen> createState() =>
      _AdminManageManagementStaffScreenState();
}

class _AdminManageManagementStaffScreenState
    extends State<AdminManageManagementStaffScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  final ImagePicker _picker = ImagePicker();

  // 🔹 Dummy Staff Data (Now includes phone & image)
  List<Map<String, dynamic>> managementStaff = [
    {
      "name": "Amit Sharma",
      "email": "amit@company.com",
      "phone": "9876543210",
      "image": null
    },
    {
      "name": "Priya Singh",
      "email": "priya@company.com",
      "phone": "9876501234",
      "image": null
    },
    {
      "name": "Ravi Kumar",
      "email": "ravi@company.com",
      "phone": "9123456780",
      "image": null
    },
  ];

  // 📸 Pick Image Helper
  Future<File?> _pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return image != null ? File(image.path) : null;
  }

  // ✏ Edit Existing Staff
  void _editStaff(int index) {
    final staff = managementStaff[index];
    final TextEditingController nameController =
    TextEditingController(text: staff["name"]);
    final TextEditingController emailController =
    TextEditingController(text: staff["email"]);
    final TextEditingController phoneController =
    TextEditingController(text: staff["phone"]);
    File? selectedImage = staff["image"];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: const Text("Edit Staff Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Profile Picture
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
                const SizedBox(height: 16),

                // 🔹 Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Email
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Phone
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
                  managementStaff[index]["name"] = nameController.text;
                  managementStaff[index]["email"] = emailController.text;
                  managementStaff[index]["phone"] = phoneController.text;
                  managementStaff[index]["image"] = selectedImage;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                    Text("${managementStaff[index]['name']} updated!"),
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

  // ➕ Add New Staff
  void _addNewStaff() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: const Text("Add New Management Staff"),
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
                const SizedBox(height: 16),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  setState(() {
                    managementStaff.add({
                      "name": nameController.text,
                      "email": emailController.text,
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

  // 🗑 Delete Staff
  void _deleteStaff(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text(
          "Are you sure you want to delete ${managementStaff[index]['name']}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                managementStaff.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Staff deleted successfully!"),
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

  // 🔹 Build Main UI
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
          "Manage Management Staff",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: managementStaff.length,
        itemBuilder: (context, index) {
          final staff = managementStaff[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: lightBlue,
                backgroundImage:
                staff["image"] != null ? FileImage(staff["image"]) : null,
                child: staff["image"] == null
                    ? Text(
                  staff["name"]![0],
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              title: Text(
                staff["name"]!,
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "${staff["email"]}\nPhone: ${staff["phone"]}",
                style: const TextStyle(height: 1.4),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.edit, color: Colors.orange),
                    onPressed: () => _editStaff(index),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.trash2, color: Colors.redAccent),
                    onPressed: () => _deleteStaff(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: _addNewStaff,
        label: const Text("Add Staff"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}