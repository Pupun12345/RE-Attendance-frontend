import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/shared/manage_users_screen.dart';
import 'package:smartcare_app/screens/admin/admin_reports_screen.dart';
import 'package:smartcare_app/screens/admin/admin_settings_screen.dart';
import 'package:smartcare_app/screens/admin/admin_holiday_setup_screen.dart';
import 'package:smartcare_app/screens/admin/admin_summary_dashboard_screen.dart';
import 'package:smartcare_app/screens/admin/admin_overtime_view_screen.dart';
import 'package:smartcare_app/screens/admin/admin_complaint_view_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildHomeDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardCard(
            icon: LucideIcons.users,
            title: "Manage Management Staff",
            subtitle: "Add, edit, or remove management-level employees.",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const ManageUsersScreen(roleFilter: 'management'),
              ),
            ),
          ),
          _buildDashboardCard(
            icon: LucideIcons.userCog,
            title: "Manage Supervisors",
            subtitle: "Handle supervisor accounts and assign roles.",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const ManageUsersScreen(roleFilter: 'supervisor'),
              ),
            ),
          ),
          _buildDashboardCard(
            icon: LucideIcons.user,
            title: "Manage Workers",
            subtitle: "Oversee worker profiles and attendance.",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const ManageUsersScreen(roleFilter: 'worker'),
              ),
            ),
          ),
          _buildDashboardCard(
            icon: LucideIcons.clock8,
            title: "Overtime View",
            subtitle: "Monitor overtime requests.",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminOvertimeViewScreen(),
              ),
            ),
          ),
          _buildDashboardCard(
            icon: LucideIcons.messageCircle,
            title: "Complaint View",
            subtitle: "Review and resolve complaints.",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminComplaintViewScreen(),
              ),
            ),
          ),
          _buildDashboardCard(
            icon: LucideIcons.calendarDays,
            title: "Set Holidays",
            subtitle: "Configure holidays.",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminHolidaySetupScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: lightBlue,
                  child: Icon(icon, color: primaryBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "View Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeDashboard(),
      const AdminSummaryDashboardScreen(),
      const ManageUsersScreen(),
      const AdminReportsScreen(),
      const AdminSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🔥 No Back Icon — Only Title + Blue Theme
      appBar: _selectedIndex == 0
          ? AppBar(
        backgroundColor: primaryBlue,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Home",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,

      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.black54,
        selectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.users),
            label: "Users",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.barChart2),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
