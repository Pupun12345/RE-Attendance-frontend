// lib/screens/shared/manage_users_screen.dart
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
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  final String? roleFilter;

  const ManageUsersScreen({
    super.key,
    this.roleFilter,
  });

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);

  List<User> _users = [];

  List<User> _filteredUsers = [];

  bool _isLoading = true;
  String? _token;

  // search controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
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

      //  Build the URL with the optional filter
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
        final loadedUsers = (data['users'] as List)
            .map((userData) => User.fromJson(userData))
            .toList()
            .cast<User>();

        setState(() {
          _users = loadedUsers;
          _filteredUsers = List<User>.from(_users);
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

  // SEARCH LOGIC
  void _filterUsers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List<User>.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          final name = user.name.toLowerCase();
          final role = user.role.toLowerCase();
          return name.contains(query) || role.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteUser(String userId) async {
    if (_token == null) {
      _showError("Not authorized.");
      return;
    }

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
      return;
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
          _filteredUsers.removeWhere((user) => user.id == userId);
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
    String title = "Manage All Users";
    if (widget.roleFilter == 'worker') title = "Manage Workers";
    if (widget.roleFilter == 'supervisor') title = "Manage Supervisors";
    if (widget.roleFilter == 'management') title = "Manage Management";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDashboardScreen(),
              ),
            );
          },
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
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
              if (widget.roleFilter == null) ...[
                _buildAddButton("Add Worker", "Worker"),
                const SizedBox(height: 10),
                _buildAddButton("Add Supervisor", "Supervisor"),
                const SizedBox(height: 10),
                _buildAddButton("Add Management Staff", "Management Staff"),
                const SizedBox(height: 25),
              ],
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by name or role...",
                    prefixIcon: const Icon(LucideIcons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              "No users found.",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _filteredUsers.map((user) {
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
  // lib/screens/shared/manage_users_screen.dart

// ... (existing code above _buildUserCard)

  Widget _buildUserCard(User user) {
    // 1. Determine the status and assign conditional colors
    final bool isActive = user.isActive;
    final Color cardColor = isActive ? Colors.white : Colors.red.shade50;
    final Color titleColor = isActive ? primaryBlue : Colors.red.shade800;
    final Color subtitleColor = isActive ? Colors.black54 : Colors.red.shade600;
    final Color iconColor = isActive ? primaryBlue : Colors.red.shade700;

    ImageProvider profileImage = const AssetImage("assets/images/profile.png");
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      profileImage = NetworkImage(user.profileImageUrl!);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      // 2. Apply conditional color to the Card
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          backgroundImage: profileImage,
          onBackgroundImageError: (exception, stackTrace) {
            // Ensure setState is only called if the widget is still mounted
            if (mounted) {
              setState(() {
                profileImage = const AssetImage("assets/images/profile.png");
              });
            }
          },
        ),
        title: Text(
          // 3. Display user ID and optionally mark as Disabled
          user.userId + (isActive ? "" : " (DISABLED)"),
          style: TextStyle(
            color: titleColor, // Apply conditional color
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          // The subtitle will show the user's name
          "${user.name} - ${user.role[0].toUpperCase() + user.role.substring(1)}",
          style: TextStyle(
            color: subtitleColor, // Apply conditional color
          ),
        ),
        trailing: IconButton(
          icon: Icon(LucideIcons.edit3,
              color: iconColor, size: 20), // Apply conditional color
          onPressed: () => _navigateToEditPage(user),
        ),
      ),
    );
  }
}
