// lib/screens/edit_user_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/models/user_model.dart';
import 'package:smartcare_app/utils/constants.dart';

class EditUserScreen extends StatefulWidget {
  final User user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _userIdController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedRole;

  // 🔹 Password controllers (only new + confirm)
  final TextEditingController _newPasswordController =
  TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isSaving = false;
  bool _isDisabling = false;

  // Track current user status in this screen
  bool _isUserDisabled = false; // assume active initially

  // Profile image state
  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _userIdController = TextEditingController(text: widget.user.userId);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _selectedRole = widget.user.role;

    _existingImageUrl = widget.user.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    // 🔹 dispose password controllers
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _toggleUserStatus() async {
    setState(() => _isDisabling = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      http.Response response;

      if (_isUserDisabled) {
        // Enable user
        final url =
        Uri.parse('$apiBaseUrl/api/v1/users/${widget.user.id}/enable');
        response = await http.patch(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } else {
        // Disable user (existing delete logic)
        final url = Uri.parse('$apiBaseUrl/api/v1/users/${widget.user.id}');
        response = await http.delete(
          url,
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;

        setState(() {
          _isUserDisabled = !_isUserDisabled;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isUserDisabled
                  ? "User disabled successfully"
                  : "User enabled successfully",
            ),
            backgroundColor: _isUserDisabled ? Colors.red : Colors.green,
          ),
        );
      } else {
        _showError(data['message'] ?? "Failed to update user status.");
      }
    } catch (e) {
      _showError("Error occurred");
    } finally {
      if (mounted) setState(() => _isDisabling = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Change Profile Photo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Gallery"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked =
    await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _selectedImageFile = File(picked.path);
      });
    }
  }

 

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ FIX 1: Check if passwords match (if entered)
    if (_newPasswordController.text.isNotEmpty) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showError("Passwords do not match.");
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('$apiBaseUrl/api/v1/users/${widget.user.id}');
      final Map<String, dynamic> body = {
        'name': _nameController.text,
        'userId': _userIdController.text,
        'phone': _phoneController.text,
        'role': _selectedRole,
      };

      if (_emailController.text.isNotEmpty) {
        body['email'] = _emailController.text;
      }

      // ✅ FIX 2: Send password to backend if user entered a new one
      if (_newPasswordController.text.isNotEmpty) {
        body['password'] = _newPasswordController.text;
      }

      // ... existing image logic ...
      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final String base64Image = base64Encode(bytes);
        body['profileImageBase64'] = base64Image;
      }

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError(data['message'] ?? 'Failed to update user.');
      }
    } catch (e) {
      _showError("Connection error");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String toggleButtonText =
    _isUserDisabled ? "Enable User" : "Disable User";
    final Color toggleButtonColor =
    _isUserDisabled ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Edit User",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.blue[50],
                          backgroundImage: _selectedImageFile != null
                              ? FileImage(_selectedImageFile!)
                              : (_existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty
                              ? NetworkImage(_existingImageUrl!)
                          as ImageProvider
                              : null),
                          child: _selectedImageFile == null &&
                              (_existingImageUrl == null ||
                                  _existingImageUrl!.isEmpty)
                              ? Icon(
                            Icons.person,
                            size: 42,
                            color: primaryBlue,
                          )
                              : null,
                        ),
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: primaryBlue,
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showImageSourceSheet,
                      child: Text(
                        "Change Photo",
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _buildTextField(_nameController, "Name *"),
              const SizedBox(height: 16),
              _buildTextField(_userIdController, "User ID *"),
              const SizedBox(height: 16),
              _buildTextField(
                _phoneController,
                "Phone Number *",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _emailController,
                "Email",
                keyboardType: TextInputType.emailAddress,
                isRequired: false,
              ),
              const SizedBox(height: 20),
              _buildRoleDropdown(),
              const SizedBox(height: 20),

              // 🔹 SECTION 1: New Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          labelStyle: TextStyle(color: primaryBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 SECTION 2: Confirm Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Confirm Password",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      labelStyle: TextStyle(color: primaryBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      : const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Toggle Disable/Enable Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isDisabling ? null : _toggleUserStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: toggleButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDisabling
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      : Text(
                    toggleButtonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role *',
        labelStyle: TextStyle(color: primaryBlue),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryBlue),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['worker', 'supervisor', 'management', 'admin']
          .map(
            (role) => DropdownMenuItem(
          value: role,
          child: Text(role[0].toUpperCase() + role.substring(1)),
        ),
      )
          .toList(),
      onChanged: (value) => setState(() => _selectedRole = value!),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
        bool isRequired = true,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "This field is required";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryBlue),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryBlue),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}