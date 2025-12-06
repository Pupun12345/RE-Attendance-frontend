// lib/screens/admin/admin_complaint_view_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/utils/constants.dart';

// --- Simple Model for Complaint View ---
class ComplaintUser {
  final String name;
  final String userId;
  ComplaintUser({required this.name, required this.userId});
  
  factory ComplaintUser.fromJson(Map<String, dynamic> json) {
    return ComplaintUser(
      name: json['name'] ?? 'Unknown',
      userId: json['userId'] ?? 'N/A',
    );
  }
}

class AdminComplaint {
  final String id;
  final String title;
  final String description;
  String status;
  final ComplaintUser user;        // The Worker
  final ComplaintUser submittedBy; // The Supervisor
  final DateTime createdAt;

  AdminComplaint({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.user,
    required this.submittedBy,
    required this.createdAt,
  });

  factory AdminComplaint.fromJson(Map<String, dynamic> json) {
    return AdminComplaint(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      user: ComplaintUser.fromJson(json['user'] ?? {}),
      // Handle missing submittedBy for old records by falling back to user
      submittedBy: ComplaintUser.fromJson(json['submittedBy'] ?? json['user'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class AdminComplaintViewScreen extends StatefulWidget {
  const AdminComplaintViewScreen({super.key});

  @override
  State<AdminComplaintViewScreen> createState() =>
      _AdminComplaintViewScreenState();
}

class _AdminComplaintViewScreenState extends State<AdminComplaintViewScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  List<AdminComplaint> _complaints = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _showError("Not authorized.");
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/complaints');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $_token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _complaints = (data['complaints'] as List)
              .map((c) => AdminComplaint.fromJson(c))
              .toList();
        });
      } else {
        _showError("Failed to load complaints.");
      }
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(AdminComplaint complaint, String newStatus) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/complaints/${complaint.id}');
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() => complaint.status = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError("Update failed.");
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'resolved') return Colors.green;
    if (status == 'in_progress') return Colors.orange;
    return Colors.redAccent;
  }

  void _showStatusMenu(BuildContext context, AdminComplaint complaint) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: ['resolved', 'in_progress', 'pending'].map((s) => ListTile(
          title: Text(s.replaceAll('_', ' ').toUpperCase()),
          onTap: () {
            Navigator.pop(context);
            _updateStatus(complaint, s);
          },
        )).toList(),
      ),
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
        title: Text("View Complaints", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _complaints.length,
              itemBuilder: (context, index) => _buildComplaintCard(_complaints[index]),
            ),
    );
  }

  Widget _buildComplaintCard(AdminComplaint complaint) {
    // Check if the submitter is different from the affected user
    final bool submittedBySomeoneElse = complaint.user.userId != complaint.submittedBy.userId;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Title + Status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaint.title,
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showStatusMenu(context, complaint),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      complaint.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: _getStatusColor(complaint.status), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(complaint.description, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            const Divider(height: 20),
            
            // ✅ THE FIX: Display logic
            if (submittedBySomeoneElse) ...[
              // Case: Supervisor submitted for Worker
              Row(
                children: [
                   Icon(LucideIcons.user, size: 14, color: Colors.blue[800]),
                   const SizedBox(width: 6),
                   Text(
                     "Affected: ${complaint.user.name} (${complaint.user.userId})",
                     style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600, fontSize: 13),
                   ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   Icon(LucideIcons.arrowUpRight, size: 14, color: Colors.grey[600]),
                   const SizedBox(width: 6),
                   Text(
                     "Submitted by: ${complaint.submittedBy.name} (Supervisor)",
                     style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic),
                   ),
                ],
              ),
            ] else ...[
              // Case: Self-submitted (or old record)
              Row(
                children: [
                   Icon(LucideIcons.user, size: 14, color: Colors.grey[600]),
                   const SizedBox(width: 6),
                   Text(
                     "${complaint.user.name} (${complaint.user.userId})",
                     style: TextStyle(color: Colors.grey[700], fontSize: 13),
                   ),
                ],
              ),
            ],

            // Date Row
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(LucideIcons.calendar, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  DateFormat("MMM dd, yyyy").format(complaint.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}