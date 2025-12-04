// lib/screens/admin/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Imports
import 'package:smartcare_app/screens/admin/admin_system_configuration_screen.dart';
import 'package:smartcare_app/screens/shared/login_screen.dart';
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightGrey = Colors.grey.shade100;

  // ✅ --- Logout Function ---
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
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

        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(LucideIcons.bell, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("General Settings"),
            _buildSettingsCard(
              icon: LucideIcons.database,
              title: "System Configuration",
              subtitle: "Adjust core application parameters and default values.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const AdminSystemConfigurationScreen(),
                  ),
                );
              },
            ),
            _buildSettingsCard(
              icon: LucideIcons.palette,
              title: "Appearance & Theme",
              subtitle: "Customize the visual theme and display options.",
              onTap: () {},
            ),
            _buildSettingsCard(
              icon: LucideIcons.clock,
              title: "Time & Locale",
              subtitle:
              "Set date format, time zones, and language preferences.",
              onTap: () {},
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("User Management"),
            _buildSettingsCard(
              icon: LucideIcons.lock,
              title: "User Roles & Permissions",
              subtitle:
              "Define and manage access levels for different user groups.",
              onTap: () {},
            ),
            _buildSettingsCard(
              icon: LucideIcons.users,
              title: "User Groups & Teams",
              subtitle: "Organize users into groups for easier management.",
              onTap: () {},
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("Communication & Notifications"),
            _buildSettingsCard(
              icon: LucideIcons.bell,
              title: "Notification Preferences",
              subtitle: "Configure how and when users receive alerts.",
              onTap: () {},
            ),
            _buildSettingsCard(
              icon: LucideIcons.messageSquare,
              title: "Message Templates",
              subtitle:
              "Edit predefined messages for various system events.",
              onTap: () {},
            ),
            const SizedBox(height: 30),


            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(LucideIcons.logOut, color: Colors.white),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent[400],
                  padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helpers
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue[50],
          child: Icon(icon, color: primaryBlue, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        trailing:
        Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
        onTap: onTap,
      ),
    );
  }
}
