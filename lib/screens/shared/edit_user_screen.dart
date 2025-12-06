// lib/screens/shared/edit_user_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Removed http_parser import 

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

  bool _isSaving = false;
  bool _isDisabling = false;

  // Profile image state
  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;
  String? _existingImageUrl;

  final List<String> _validRoles = ['worker', 'supervisor', 'management', 'admin'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _userIdController = TextEditingController(text: widget.user.userId);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    
    String incomingRole = widget.user.role.toLowerCase();
    if (_validRoles.contains(incomingRole)) {
      _selectedRole = incomingRole;
    } else {
      _selectedRole = 'worker';
    }

    _existingImageUrl = widget.user.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- API: Update User ---
  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Detect Changes
    List<String> changedFields = [];
    String currentName = _nameController.text.trim();
    String currentPhone = _phoneController.text.trim();
    String currentEmail = _emailController.text.trim();

    if (currentName != widget.user.name) changedFields.add("Name");
    if (currentPhone != widget.user.phone) changedFields.add("Phone Number");
    if (currentEmail != (widget.user.email ?? '').trim()) changedFields.add("Email");
    if (_selectedRole != widget.user.role.toLowerCase()) changedFields.add("Role");
    if (_selectedImageFile != null) changedFields.add("Photo");

    if (changedFields.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("No changes detected.")),
       );
       return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('$apiBaseUrl/api/v1/users/${widget.user.id}');

      http.Response response;

      // --- SCENARIO A: Text Only (JSON) ---
      if (_selectedImageFile == null) {
        final body = {
          'name': currentName,
          'userId': _userIdController.text.trim(),
          'phone': currentPhone,
          'role': _selectedRole,
          'email': currentEmail,
        };

        response = await http.put(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

      } else {
        // --- SCENARIO B: Image Upload (Multipart) ---
        var request = http.MultipartRequest('PUT', url);
        request.headers['Authorization'] = 'Bearer $token';

        request.fields['name'] = currentName;
        request.fields['userId'] = _userIdController.text.trim();
        request.fields['phone'] = currentPhone;
        request.fields['role'] = _selectedRole;
        if (currentEmail.isNotEmpty) {
          request.fields['email'] = currentEmail;
        }

        // ✅ FIX: Use fromBytes instead of fromPath to avoid "PathNotFoundException"
        // We read the file immediately. If it fails, we catch it here.
        if (await _selectedImageFile!.exists()) {
            final imageBytes = await _selectedImageFile!.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'profileImage', 
              imageBytes,
              filename: 'profile_pic.jpg' // Generic name is fine
            ));
        } else {
            throw Exception("Selected image file not found. Please pick image again.");
        }

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && (data['success'] == true || data['success'] == "true")) {
        // ✅ Clear Image Cache so new photo shows
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
          try {
             await NetworkImage(_existingImageUrl!).evict(); 
          } catch (e) {
             // ignore cache error
          }
        }

        if (!mounted) return;

        // Construct success message
        String successMessage;
        if (changedFields.length == 1) {
          successMessage = "${changedFields.first} updated successfully!";
        } else {
          successMessage = "Updated successfully: ${changedFields.join(', ')}";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        _showError(data['message'] ?? 'Failed to update user.');
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- API: Disable User (Unchanged) ---
  Future<void> _disableUser() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Disable User"),
        content: const Text("Are you sure you want to disable this account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Disable", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isDisabling = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('$apiBaseUrl/api/v1/users/${widget.user.id}');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User disabled successfully"), backgroundColor: Colors.red),
        );
        Navigator.pop(context, true);
      } else {
        _showError(data['message'] ?? "Failed to disable user.");
      }
    } catch (e) {
      _showError("Error occurred: $e");
    } finally {
      if (mounted) setState(() => _isDisabling = false);
    }
  }

  // --- Image Picking Logic (Unchanged) ---
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Change Profile Photo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
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
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _selectedImageFile = File(picked.path);
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  // --- UI Build (Unchanged) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text("Edit User", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
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
              // Profile Photo Avatar
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.blue[50],
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                    ? NetworkImage(_existingImageUrl!) as ImageProvider
                                    : null),
                            child: _selectedImageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
                                ? Icon(Icons.person, size: 42, color: primaryBlue)
                                : null,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: primaryBlue,
                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showImageSourceSheet,
                      child: Text("Change Photo", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _buildTextField(_nameController, "Name *"),
              const SizedBox(height: 16),
              _buildTextField(_userIdController, "User ID *", isReadOnly: true), 
              const SizedBox(height: 16),
              _buildTextField(_phoneController, "Phone Number *", keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(_emailController, "Email", keyboardType: TextInputType.emailAddress, isRequired: false),
              const SizedBox(height: 20),
              
              _buildRoleDropdown(),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isDisabling ? null : _disableUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isDisabling
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Disable User", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryBlue), borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _validRoles
          .map((role) => DropdownMenuItem(value: role, child: Text(role[0].toUpperCase() + role.substring(1))))
          .toList(),
      onChanged: (value) => setState(() => _selectedRole = value!),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, bool isRequired = true, bool isReadOnly = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: isReadOnly,
      style: isReadOnly ? TextStyle(color: Colors.grey.shade600) : null,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "This field is required";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryBlue),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryBlue), borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isReadOnly ? Colors.grey.shade200 : Colors.white,
      ),
    );
  }
}