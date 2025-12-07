// lib/screens/supervisor/worker_submit_complaint_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:smartcare_app/utils/constants.dart'; // Your constants

class WorkerSubmitComplaintScreen extends StatefulWidget {
  final String name;
  final String userId; // Display ID (e.g. W001)
  final String dbId;   // ✅ Added: MongoDB _id of the worker (REQUIRED for API)

  const WorkerSubmitComplaintScreen({
    super.key,
    required this.name,
    required this.userId,
    required this.dbId, // ✅ Added: Constructor now requires this
  });

  @override
  State<WorkerSubmitComplaintScreen> createState() =>
      _WorkerSubmitComplaintScreenState();
}

class _WorkerSubmitComplaintScreenState
    extends State<WorkerSubmitComplaintScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isSubmitting = false;

  Future<void> _pickFromCamera() async {
    final XFile? img =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (img != null) {
      setState(() => _selectedImage = File(img.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? img =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() => _selectedImage = File(img.path));
    }
  }

  // ✅ ACTUAL API SUBMISSION LOGIC
  void _submitComplaint() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill title and description."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$apiBaseUrl/api/v1/complaints"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descController.text;
      
      // ✅ SEND THE WORKER'S DB ID
      request.fields['workerId'] = widget.dbId; 

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'complaintImage',
            _selectedImage!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint Submitted Successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? "Failed to submit");
      }
    } catch (e) {
      _showError("Connection error: $e");
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Submit Complaint",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: themeBlue.withOpacity(0.08),
                    child: Icon(Icons.person, color: themeBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: ${widget.userId}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
             // Complaint Title
            const Text(
              "Complaint Title",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Enter title...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
             const Text(
              "Description",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe your issue...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text("Take Photo", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: Icon(Icons.upload, color: themeBlue),
                    label: Text("Upload", style: TextStyle(color: themeBlue)),
                  ),
                ),
              ],
            ),
             if (_selectedImage != null) ...[
              const SizedBox(height: 8),
              Text("Image selected: ${_selectedImage!.path.split('/').last}", style: const TextStyle(fontSize: 12)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Complaint", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}