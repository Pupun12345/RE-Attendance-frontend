import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:smartcare_app/utils/constants.dart';

class WorkerSubmitComplaintScreen extends StatefulWidget {
  final String name;
  final String userId;        // Display ID (e.g., U-001)
  final String workerMongoId; // The Database ID (e.g., 65a...)

  const WorkerSubmitComplaintScreen({
    super.key,
    required this.name,
    required this.userId,
    required this.workerMongoId, // ✅ This ID identifies the worker
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

  final String _apiUrl = apiBaseUrl;

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

  Future<void> _submitComplaint() async {
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

      if (token == null) {
        _showError("Authentication error. Please login again.");
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_apiUrl/api/v1/complaints"),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // ✅ Sending the Worker's ID so the backend assigns it to them
      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descController.text.trim();
      request.fields['workerId'] = widget.workerMongoId;

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
      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Complaint submitted for ${widget.name}"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        _showError(responseData['message'] ?? "Failed to submit complaint");
      }
    } catch (e) {
      _showError("Server Connection Error");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
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
            // Worker Info Card
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
                          "For: ${widget.name}",
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

            // Description
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

            // Photo Selection
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
                    label: Text("Upload Image", style: TextStyle(color: themeBlue)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: themeBlue)),
                  ),
                ),
              ],
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 8),
              Text(
                "Image selected: ${_selectedImage!.path.split('/').last}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],

            // Submit Button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Complaint",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}