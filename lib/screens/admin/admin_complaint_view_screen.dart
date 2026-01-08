// lib/screens/admin/admin_complaint_view_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/utils/constants.dart';

// ------------------ MODELS ------------------

class ComplaintUser {
  final String name;
  final String userId;

  ComplaintUser({required this.name, required this.userId});

  factory ComplaintUser.fromJson(dynamic json) {
    if (json == null) {
      return ComplaintUser(name: 'Unknown', userId: 'N/A');
    }
    if (json is String) {
      return ComplaintUser(name: 'Unknown', userId: json);
    }
    if (json is Map<String, dynamic>) {
      return ComplaintUser(
        name: json['name'] ?? 'Unknown',
        userId: json['userId'] ?? 'N/A',
      );
    }
    return ComplaintUser(name: 'Unknown', userId: 'N/A');
  }
}

class AdminComplaint {
  final String id;
  final String title;
  final String description;
  final ComplaintUser user;
  final ComplaintUser submittedBy;
  final DateTime createdAt;

  AdminComplaint({
    required this.id,
    required this.title,
    required this.description,
    required this.user,
    required this.submittedBy,
    required this.createdAt,
  });

  factory AdminComplaint.fromJson(Map<String, dynamic> json) {
    return AdminComplaint(
      id: json['_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      user: ComplaintUser.fromJson(json['user']),
      submittedBy:
      ComplaintUser.fromJson(json['submittedBy'] ?? json['user']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// ------------------ SCREEN ------------------

class AdminComplaintViewScreen extends StatefulWidget {
  const AdminComplaintViewScreen({super.key});

  @override
  State<AdminComplaintViewScreen> createState() =>
      _AdminComplaintViewScreenState();
}

class _AdminComplaintViewScreenState extends State<AdminComplaintViewScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);

  List<AdminComplaint> _allComplaints = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  // ------------------ API ------------------

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/complaints'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _allComplaints = (data['complaints'] as List)
              .map((c) => AdminComplaint.fromJson(c))
              .toList();
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ------------------ LAST 7 DAYS FILTER ------------------

  List<AdminComplaint> get _last7DaysComplaints {
    final DateTime last7Days =
    DateTime.now().subtract(const Duration(days: 7));

    return _allComplaints
        .where((c) => c.createdAt.isAfter(last7Days))
        .toList();
  }

  // ------------------ UI ------------------

  @override
  Widget build(BuildContext context) {
    final complaints = _last7DaysComplaints;

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
          "Complaints",
          style:
          TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(
        child:
        CircularProgressIndicator(color: primaryBlue),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: complaints.length,
        itemBuilder: (_, i) =>
            _buildComplaintCard(complaints[i]),
      ),
    );
  }

  Widget _buildComplaintCard(AdminComplaint complaint) {
    final bool submittedBySomeoneElse =
        complaint.user.userId != complaint.submittedBy.userId;

    return Card(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.title,
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(complaint.description),
            const Divider(height: 20),

            if (submittedBySomeoneElse) ...[
              Row(
                children: [
                  Icon(LucideIcons.user,
                      size: 14, color: Colors.blue[800]),
                  const SizedBox(width: 6),
                  Text(
                    "Affected: ${complaint.user.name} (${complaint.user.userId})",
                    style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Submitted by: ${complaint.submittedBy.name} (Supervisor)",
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ] else
              Text(
                "${complaint.user.name} (${complaint.user.userId})",
                style:
                TextStyle(color: Colors.grey[700], fontSize: 13),
              ),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat("MMM dd, yyyy")
                    .format(complaint.createdAt),
                style:
                TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}