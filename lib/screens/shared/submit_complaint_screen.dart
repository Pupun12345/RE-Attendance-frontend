// lib/screens/shared/submit_complaint_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:smartcare_app/screens/supervisor/worker_submit_complaint_screen.dart';

enum ComplaintTab { newTab,}

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
  
  // Worker List State
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allWorkers = [];      
  List<dynamic> _filteredWorkers = []; 
  bool _isLoadingWorkers = true;

  // Complaint History State
  //List<dynamic> _pendingComplaints = [];
  //List<dynamic> _resolvedComplaints = [];
  //bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchWorkers(); 
    //_fetchComplaintHistory(); // Initial fetch

    _searchController.addListener(_filterWorkers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // --- 1. DATA FETCHING ---
  Future<void> _refreshData() async {
    if (_allWorkers.isEmpty) await _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse("$_apiUrl/api/v1/users?role=worker"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allWorkers = data['users'];
            _filteredWorkers = _allWorkers;
            _isLoadingWorkers = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingWorkers = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWorkers = false);
    }
  }

  void _filterWorkers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWorkers = _allWorkers.where((worker) {
        final name = worker['name']?.toString().toLowerCase() ?? '';
        final userId = worker['userId']?.toString().toLowerCase() ?? '';
        return name.contains(query) || userId.contains(query);
      }).toList();
    });
  }

  // ✅ ROBUST HISTORY FETCHING
  /*Future<void> _fetchComplaintHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse("$_apiUrl/api/v1/complaints"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> all = data['complaints'];

        if (mounted) {
          setState(() {
            // Filter logic: Handles 'pending', 'in_progress', 'resolved'
            _pendingComplaints = all.where((c) {
              final status = c['status']?.toString().toLowerCase().trim() ?? '';
              return status == 'pending' || status == 'in_progress';
            }).toList();

            _resolvedComplaints = all.where((c) {
              final status = c['status']?.toString().toLowerCase().trim() ?? '';
              return status == 'resolved';
            }).toList();
          });
        }
      } else {
        print("Backend Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching history: $e");
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }*/

  Future<void> captureImage() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked != null) setState(() => selectedImage = File(picked.path));
  }
  
  Future<void> pickImageFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => selectedImage = File(picked.path));
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
      var request = http.MultipartRequest('POST', Uri.parse("$_apiUrl/api/v1/complaints"));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = titleController.text;
      request.fields['description'] = descriptionController.text;
      if (selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('complaintImage', selectedImage!.path, contentType: MediaType('image', 'jpeg')));
      }
      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 201) {
        _showSuccess("Complaint submitted!");
        //_fetchComplaintHistory();
        setState(() { titleController.clear(); descriptionController.clear(); selectedImage = null; });
      } else {
        _showError("Failed to submit");
      }
    } catch (e) {_showError("Error: $e");} 
    finally { if(mounted) setState(() => _isSubmitting = false); }
  }

  void _showError(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red)); }
  void _showSuccess(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green)); }

  void _onTabSelected(ComplaintTab tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in_progress': return Colors.orange;
      case 'pending': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),

      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTabButton("New", ComplaintTab.newTab, themeBlue),
                ],
              ),
              const SizedBox(height: 18),

              _buildTabContent(),

              // New Complaint Form
              if (_selectedTab == ComplaintTab.newTab) ...[
                const SizedBox(height: 20),
                const Divider(),
                const Center(child: Text("Or submit a general complaint", style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 10),
                
                const Text("Complaint Title", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(controller: titleController, decoration: InputDecoration(hintText: "Enter title...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white)),
                
                const SizedBox(height: 16),
                const Text("Description", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(controller: descriptionController, maxLines: 3, decoration: InputDecoration(hintText: "Describe issue...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white)),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(onPressed: captureImage, icon: const Icon(Icons.camera_alt, color: Colors.white), label: const Text("Take Photo", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: themeBlue))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(onPressed: pickImageFromGallery, icon: Icon(Icons.file_upload, color: themeBlue), label: Text("Upload Image", style: TextStyle(color: themeBlue)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: themeBlue)))),
                  ],
                ),
                
                if (selectedImage != null) ...[
                  const SizedBox(height: 15),
                  Center(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(selectedImage!, height: 140, width: 140, fit: BoxFit.cover))),
                ],

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(onPressed: _isSubmitting ? null : submitComplaint, style: ElevatedButton.styleFrom(backgroundColor: themeBlue), child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit General Complaint", style: TextStyle(color: Colors.white))),
                ),
                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, ComplaintTab tab, Color color) {
    bool isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
          ),
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case ComplaintTab.newTab:
        return _buildNewTabContent();
    }
  }

  Widget _buildNewTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Worker",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _isLoadingWorkers
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
              : _filteredWorkers.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Text("No workers found."),
          )
              : ListView.separated(
            shrinkWrap: true,
            itemCount: _filteredWorkers.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final worker = _filteredWorkers[index];
              final String name = worker['name'] ?? 'Unknown';
              final String userId = worker['userId'] ?? 'N/A';
              final String dbId =
                  worker['_id'] ?? worker['id'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  themeBlue.withOpacity(0.1),
                  child: Icon(Icons.person, color: themeBlue),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  userId,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkerSubmitComplaintScreen(
                            name: name,
                            userId: userId,
                            dbId: dbId,
                          ),
                    ),
                  );
                  // ❌ _fetchComplaintHistory() REMOVED
                },
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildComplaintList({required List<dynamic> items, required String emptyText}) {
    if (items.isEmpty) {
      return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(emptyText)));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final workerName = item['user'] != null ? item['user']['name'] : 'Self';
        
        final String status = item['status'] ?? 'pending';
        final Color statusColor = _getStatusColor(status);
        
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            title: Text(item["title"] ?? "No Title", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item["description"] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text("For: $workerName", style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w600)),
                ])
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                status.toString().replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w600, 
                  color: statusColor
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}