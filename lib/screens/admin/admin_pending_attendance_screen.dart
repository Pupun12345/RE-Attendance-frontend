// lib/screens/admin_pending_attendance_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/models/pending_attendance_model.dart';
import 'package:smartcare_app/utils/constants.dart';

class AdminPendingAttendanceScreen extends StatefulWidget {
  const AdminPendingAttendanceScreen({super.key});

  @override
  State<AdminPendingAttendanceScreen> createState() =>
      _AdminPendingAttendanceScreenState();
}

// 🔹 3 category: Supervisor, Management, Worker
enum PendingCategory { supervisor, management, worker }

class _AdminPendingAttendanceScreenState
    extends State<AdminPendingAttendanceScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  List<PendingAttendance> _pendingRequests = [];
  bool _isLoading = true;
  String? _token;

  PendingCategory _selectedCategory = PendingCategory.supervisor;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
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

  // 🔹 Category -> role string (API ke role ke hisaab se)
  String _categoryToRole(PendingCategory category) {
    switch (category) {
      case PendingCategory.supervisor:
        return 'supervisor';
      case PendingCategory.management:
        return 'management';
      case PendingCategory.worker:
        return 'worker';
    }
  }

  String _categoryToTitle(PendingCategory category) {
    switch (category) {
      case PendingCategory.supervisor:
        return 'Supervisor';
      case PendingCategory.management:
        return 'Management';
      case PendingCategory.worker:
        return 'Workers';
    }
  }

  IconData _categoryToIcon(PendingCategory category) {
    switch (category) {
      case PendingCategory.supervisor:
        return LucideIcons.userCheck;
      case PendingCategory.management:
        return LucideIcons.briefcase; 
      case PendingCategory.worker:
        return LucideIcons.users;
    }
  }

  
  String _extractUserRole(dynamic user) {
    try {
      final r = user.role ?? user.userType ?? user.type ?? '';
      return r.toString();
    } catch (_) {
      return '';
    }
  }

 
  List<PendingAttendance> get _filteredRequests {
    final role = _categoryToRole(_selectedCategory).toLowerCase();
    return _pendingRequests.where((req) {
      final userRole = _extractUserRole(req.user).toLowerCase();
      return userRole == role;
    }).toList();
  }

  // ✅ API should add here 
  Future<void> _fetchPendingRequests() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        _showError("Not authorized.");
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/attendance/pending');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingRequests = (data['data'] as List)
              .map((req) => PendingAttendance.fromJson(req))
              .toList();
        });
      } else {
        _showError("Failed to load pending requests.");
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Approve / Reject action
  Future<void> _handleAttendanceAction(
      PendingAttendance request, bool isApproved) async {
    if (_token == null) {
      _showError("Not authorized.");
      return;
    }

    final action = isApproved ? 'approve' : 'reject';
    final url = Uri.parse('$apiBaseUrl/api/v1/attendance/${request.id}/$action');

    try {
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _pendingRequests.remove(request);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproved
                  ? "✅ Attendance of ${request.user.name} approved!"
                  : "❌ Attendance of ${request.user.name} rejected!",
            ),
            backgroundColor: isApproved ? Colors.green : Colors.redAccent,
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Failed to process request.');
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    }
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
        title: Text(
          "Pending Attendance",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
        onRefresh: _fetchPendingRequests,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // 🔹 Upar 3 category cards
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child:
                    _buildCategoryCard(PendingCategory.supervisor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                    _buildCategoryCard(PendingCategory.management),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCategoryCard(PendingCategory.worker),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 Niche filtered list
            Expanded(
              child: _filteredRequests.isEmpty
                  ? ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                      height:
                      MediaQuery.of(context).size.height / 4),
                  Center(
                    child: Text(
                      "No pending ${_categoryToTitle(_selectedCategory)} attendance.",
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 16),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredRequests.length,
                itemBuilder: (context, index) {
                  final request = _filteredRequests[index];
                  return _buildRequestCard(request);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Category card widget (Supervisor / Management / Worker)
  Widget _buildCategoryCard(PendingCategory category) {
    final isSelected = _selectedCategory == category;
    final title = _categoryToTitle(category);
    final icon = _categoryToIcon(category);
    final expectedRole = _categoryToRole(category).toLowerCase();

    final count = _pendingRequests.where((req) {
      final userRole = _extractUserRole(req.user).toLowerCase();
      return userRole == expectedRole;
    }).length;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Card(
        color: isSelected ? primaryBlue : Colors.white,
        elevation: isSelected ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : primaryBlue,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  "$title ($count)",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Individual request card
  Widget _buildRequestCard(PendingAttendance staff) {
    ImageProvider profileImage =
    const AssetImage("assets/images/profile.png");

    if (staff.user.profileImageUrl != null &&
        staff.user.profileImageUrl!.isNotEmpty) {
      profileImage = NetworkImage(staff.user.profileImageUrl!);
    }

    final roleLabel = _extractUserRole(staff.user);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 User info row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: lightBlue,
                  backgroundImage: profileImage,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (roleLabel.isNotEmpty)
                        Text(
                          "Role: $roleLabel",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        "Time: ${DateFormat("hh:mm a").format(staff.checkInTime)}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Date: ${DateFormat("MMM dd, yyyy").format(staff.checkInTime)}",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 🔹 Approve / Reject buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _handleAttendanceAction(staff, true),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _handleAttendanceAction(staff, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}