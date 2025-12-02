// lib/screens/manage_users_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/screens/shared/add_worker_screen.dart';
import 'package:smartcare_app/screens/shared/add_supervisor_screen.dart';
import 'package:smartcare_app/screens/shared/add_management_staff_screen.dart';
import 'package:smartcare_app/screens/shared/edit_user_screen.dart';
import 'package:smartcare_app/models/user_model.dart';
import 'package:smartcare_app/utils/constants.dart';

class ManageUsersScreen extends StatefulWidget {
  final String? roleFilter; // ✅ 1. Add this filter

  const ManageUsersScreen({
    super.key,
    this.roleFilter, // ✅ 2. Add to constructor
  });

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  List<User> _users = []; 
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _showError("Not authorized.");
        return;
      }

      // ✅ 3. Build the URL with the optional filter
      String urlString = '$apiBaseUrl/api/v1/users';
      if (widget.roleFilter != null) {
        urlString += '?role=${widget.roleFilter}';
      }
      final url = Uri.parse(urlString);

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = (data['users'] as List)
              .map((userData) => User.fromJson(userData))
              .toList();
        });
      } else {
        _showError("Failed to load users.");
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    if (_token == null) {
      _showError("Not authorized.");
      return;
    }

    // Show a confirmation dialog
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to disable this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete != true) {
      return; // User cancelled
    }

    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/users/$userId');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _users.removeWhere((user) => user.id == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User disabled successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(data['message'] ?? "Failed to delete user.");
      }
    } catch (e) {
      _showError("An error occurred.");
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

  void _navigateToAddPage(String role) async {
    Widget page;

    if (role == "Worker") {
      page = const AddWorkerScreen();
    } else if (role == "Supervisor") {
      page = const AddSupervisorScreen();
    } else {
      page = const AddManagementStaffScreen();
    }

    // Refresh user list after returning from the add page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (result == true) {
      _fetchUsers();
    }
  }

  void _navigateToEditPage(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(user: user),
      ),
    );

    if (result == true) {
      _fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 4. Determine the title based on the filter
    String title = "";
    if (widget.roleFilter == 'worker') title = "Manage Workers";
    if (widget.roleFilter == 'supervisor') title = "Manage Supervisors";
    if (widget.roleFilter == 'management') title = "Manage Management";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        // ✅ 5. Use the dynamic title
        title: Text(
          title,
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 6. Only show 'Add' buttons if there's no filter
              if (widget.roleFilter == null) ...[
                _buildAddButton("Add Worker", "Worker"),
                const SizedBox(height: 10),
                _buildAddButton("Add Supervisor", "Supervisor"),
                const SizedBox(height: 10),
                _buildAddButton("Add Management Staff", "Management Staff"),
                const SizedBox(height: 25),
              ],
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              "No users found.",
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 15),
                            ),
                          ),
                        )
                      : Column(
                          children: _users.map((user) {
                            return _buildUserCard(user); 
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(String text, String role) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToAddPage(role),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    ImageProvider profileImage =
        const AssetImage("assets/images/profile.png");
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      profileImage = NetworkImage(user.profileImageUrl!);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          backgroundImage: profileImage,
          onBackgroundImageError: (exception, stackTrace) {
            // Handle broken image links gracefully
            setState(() {
              profileImage = const AssetImage("assets/images/profile.png");
            });
          },
        ),
        title: Text(
          user.name,
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(user.role[0].toUpperCase() + user.role.substring(1)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(LucideIcons.edit3, color: primaryBlue, size: 20),
              onPressed: () => _navigateToEditPage(user), 
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteUser(user.id),
            ),
          ],
        ),
      ),
    );
  }
}