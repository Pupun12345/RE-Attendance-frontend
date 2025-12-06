import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';

enum ComplaintTab { newTab, pending, resolved }

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool _isSubmitting = false;

  File? selectedImage;

  final String _apiUrl = apiBaseUrl;

  ComplaintTab _selectedTab = ComplaintTab.newTab;


  bool _showWorkerSection = false;

  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _allWorkers = [
    {"name": "Umesh Kumar", "id": "W001"},
    {"name": "Ravi Sharma", "id": "W002"},
    {"name": "Amit Singh", "id": "W003"},
    {"name": "Rohan Verma", "id": "W004"},
  ];
  List<Map<String, String>> _filteredWorkers = [];

  final List<Map<String, String>> _pendingComplaints = [
    {
      "title": "Helmet not provided",
      "worker": "Umesh Kumar (W001)",
      "date": "06 Dec 2025",
    },
    {
      "title": "Water shortage at site",
      "worker": "Ravi Sharma (W002)",
      "date": "05 Dec 2025",
    },
  ];

  final List<Map<String, String>> _resolvedComplaints = [
    {
      "title": "Gloves issue resolved",
      "worker": "Amit Singh (W003)",
      "date": "03 Dec 2025",
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredWorkers = List<Map<String, String>>.from(_allWorkers);

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredWorkers = _allWorkers
            .where((w) =>
        w["name"]!.toLowerCase().contains(query) ||
            w["id"]!.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImageFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> captureImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => selectedImage = File(picked.path));
      }
    } catch (e) {
      _showError("Camera not available on this device.");
    }
  }

  Future<void> submitComplaint() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      _showError("Title and description cannot be empty.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _showError("You are not logged in. Please restart the app.");
        setState(() => _isSubmitting = false);
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_apiUrl/api/v1/complaints"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = titleController.text;
      request.fields['description'] = descriptionController.text;

      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'complaintImage',
            selectedImage!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        _showSuccess("Complaint submitted successfully!");

        setState(() {
          titleController.clear();
          descriptionController.clear();
          selectedImage = null;
        });
      } else {
        _showError(responseData['message'] ?? "Failed to submit complaint");
      }
    } catch (e) {
      _showError("Could not connect to server. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _onTabSelected(ComplaintTab tab) {
    setState(() {
      _selectedTab = tab;

      // 👉 New logic:
      // - Pending / Resolved: worker section off
      // - New: worker section tab-click se ON hoga
      if (tab == ComplaintTab.newTab) {
        _showWorkerSection = true;
      } else {
        _showWorkerSection = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const SupervisorDashboardScreen()),
            );
          },
        ),
        title: const Text(
          "Submit Complaint",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP: tabs
            Row(
              children: [
                // NEW
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabSelected(ComplaintTab.newTab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == ComplaintTab.newTab
                            ? themeBlue.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: themeBlue,
                          width:
                          _selectedTab == ComplaintTab.newTab ? 1.8 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "New",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: themeBlue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // PENDING
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabSelected(ComplaintTab.pending),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == ComplaintTab.pending
                            ? Colors.orange.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange,
                          width:
                          _selectedTab == ComplaintTab.pending ? 1.8 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Pending",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // RESOLVED
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabSelected(ComplaintTab.resolved),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == ComplaintTab.resolved
                            ? Colors.green.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green,
                          width:
                          _selectedTab == ComplaintTab.resolved ? 1.8 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Resolved",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildTabContent(),

            const SizedBox(height: 18),


            if (_selectedTab == ComplaintTab.newTab) ...[
              const Text(
                "Complaint Title",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Enter title...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Description",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe your issue...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: captureImage,
                      icon:
                      const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text(
                        "Take Photo",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: pickImageFromGallery,
                      icon: Icon(Icons.file_upload, color: themeBlue),
                      label: Text(
                        "Upload Image",
                        style: TextStyle(
                            color: themeBlue,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: themeBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (selectedImage != null) ...[
                const SizedBox(height: 15),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      selectedImage!,
                      height: 140,
                      width: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    "Submit Complaint",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case ComplaintTab.newTab:
      // 🔹 Pehli baar screen pe aane par _showWorkerSection = false,
      // isliye yahan kuch nahi dikhega (sirf neeche wala complaint card dikhega)
        if (!_showWorkerSection) return const SizedBox.shrink();
        return _buildNewTabContent();

      case ComplaintTab.pending:
        return _buildComplaintList(
          title: "Pending Complaints",
          items: _pendingComplaints,
          emptyText: "No pending complaints.",
          badgeColor: Colors.orange,
        );
      case ComplaintTab.resolved:
        return _buildComplaintList(
          title: "Resolved Complaints",
          items: _resolvedComplaints,
          emptyText: "No resolved complaints.",
          badgeColor: Colors.green,
        );
    }
  }

  // New Tab → Worker search + list
  Widget _buildNewTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Worker",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search worker by name or ID...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _filteredWorkers.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "No workers found.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredWorkers.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final worker = _filteredWorkers[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: themeBlue.withOpacity(0.08),
                  child: Icon(
                    Icons.person_outline,
                    color: themeBlue,
                  ),
                ),
                title: Text(
                  worker["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  worker["id"] ?? "",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                onTap: () {

                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Pending / Resolved list UI
  Widget _buildComplaintList({
    required String title,
    required List<Map<String, String>> items,
    required String emptyText,
    required Color badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              emptyText,
              style:
              const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  title: Text(
                    item["title"] ?? "",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item["worker"] != null)
                        Text(
                          item["worker"]!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      if (item["date"] != null)
                        Text(
                          item["date"]!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      title.contains("Pending") ? "Pending" : "Resolved",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
