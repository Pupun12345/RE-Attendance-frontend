import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartcare_app/models/user_model.dart';
import 'edit_user_controller.dart';

class EditUserView extends StatelessWidget {
  final User user;
  const EditUserView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditUserController(user: user));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text("Edit User",
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
              // Profile Photo
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Obx(() {
                          ImageProvider? imgProvider;
                          if (controller.selectedImageFile.value != null) {
                            imgProvider =
                                FileImage(controller.selectedImageFile.value!);
                          } else if (controller.existingImageUrl.value != null &&
                              controller.existingImageUrl.value!.isNotEmpty) {
                            imgProvider = NetworkImage(
                                controller.existingImageUrl.value!);
                          }
                          return CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.blue[50],
                            backgroundImage: imgProvider,
                            child: imgProvider == null
                                ? Icon(Icons.person,
                                    size: 42, color: controller.primaryBlue)
                                : null,
                          );
                        }),
                        GestureDetector(
                          onTap: controller.showImageSourceSheet,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: controller.primaryBlue,
                            child: const Icon(Icons.edit,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: controller.showImageSourceSheet,
                      child: Text("Change Photo",
                          style: TextStyle(
                              color: controller.primaryBlue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(controller, controller.nameController, "Name *"),
              const SizedBox(height: 16),
              _buildTextField(
                  controller, controller.userIdController, "User ID *"),
              const SizedBox(height: 16),
              _buildTextField(
                  controller, controller.phoneController, "Phone Number *",
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(
                  controller, controller.emailController, "Email",
                  keyboardType: TextInputType.emailAddress, isRequired: false),
              const SizedBox(height: 20),
              _buildRoleDropdown(controller),
              const SizedBox(height: 20),

              // Password Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Password",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: controller.primaryBlue)),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  child: TextFormField(
                    controller: controller.newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      labelStyle:
                          TextStyle(color: controller.primaryBlue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Confirm Password",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: controller.primaryBlue)),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  child: TextFormField(
                    controller: controller.confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      labelStyle:
                          TextStyle(color: controller.primaryBlue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.updateUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.primaryBlue,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: controller.isSaving.value
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text("Save Changes",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    )),
              ),
              const SizedBox(height: 12),

              // Disable/Enable Button
              Obx(() {
                final isDisabled = controller.isUserDisabled.value;
                return SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isDisabling.value
                          ? null
                          : controller.toggleUserStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDisabled ? Colors.green : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: controller.isDisabling.value
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Text(
                              isDisabled ? "Enable User" : "Disable User",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown(EditUserController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedRole.value,
          decoration: InputDecoration(
            labelText: 'Role *',
            labelStyle: TextStyle(color: controller.primaryBlue),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: controller.primaryBlue),
                borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: ['worker', 'supervisor', 'management', 'admin']
              .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(
                        role[0].toUpperCase() + role.substring(1)),
                  ))
              .toList(),
          onChanged: (value) => controller.selectedRole.value = value!,
        ));
  }

  Widget _buildTextField(
    EditUserController controller,
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "This field is required";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: controller.primaryBlue),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: controller.primaryBlue),
            borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
