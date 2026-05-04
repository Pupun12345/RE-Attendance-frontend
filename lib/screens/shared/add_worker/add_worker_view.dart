import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'add_worker_controller.dart';

class AddWorkerView extends GetView<AddWorkerController> {
  const AddWorkerView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AddWorkerController());
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text("Add Worker",
            style: TextStyle(
                color: controller.primaryBlue, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: controller.primaryBlue),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: controller.showImagePickerOptions,
                child: Column(
                  children: [
                    Obx(() => CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue[50],
                          backgroundImage: controller.profileImage.value != null
                              ? FileImage(controller.profileImage.value!)
                              : null,
                          child: controller.profileImage.value == null
                              ? Icon(LucideIcons.camera,
                                  size: 34, color: controller.primaryBlue)
                              : null,
                        )),
                    const SizedBox(height: 8),
                    Text("Add Profile Photo",
                        style: TextStyle(
                            color: controller.primaryBlue,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _buildTextField(controller.nameController, "Name *"),
              const SizedBox(height: 16),
              _buildTextField(controller.userIdController, "User ID *"),
              const SizedBox(height: 16),
              _buildTextField(controller.phoneController, "Phone Number *",
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              Obx(() => Row(
                    children: [
                      Checkbox(
                        value: controller.isConfirmed.value,
                        activeColor: controller.primaryBlue,
                        onChanged: (v) =>
                            controller.isConfirmed.value = v ?? false,
                      ),
                      const Expanded(
                        child: Text(
                          "I confirm that the above details are accurate and comply with company policies.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveWorker,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text("Save Worker",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "This field is required";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: controller.primaryBlue),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: controller.primaryBlue, width: 2),
            borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
