import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/models/user_model.dart';
import 'package:smartcare_app/screens/admin/views/admin_dashboard_view.dart';

import '../add_management_staff/add_management_staff_view.dart';
import '../add_supervisor/add_supervisor_view.dart';
import '../add_worker/add_worker_view.dart';
import '../edit_user/edit_user_view.dart';
import 'manage_users_controller.dart';

class ManageUsersView extends StatelessWidget {
  final String? roleFilter;
  const ManageUsersView({super.key, this.roleFilter});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManageUsersController(roleFilter: roleFilter));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: controller.primaryBlue,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.offAll(() => const AdminDashboardView()),
        ),
        // ✅ Obx hataya — title plain getter hai, RxString nahi
        title: Text(
          controller.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchUsers,
        child: Obx(() {
          // ✅ Saara reactive content ek hi Obx mein
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ CustomScrollView + SliverList = smooth scrolling
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Add buttons (sirf jab roleFilter == null)
                    if (roleFilter == null) ...[
                      _buildAddButton(controller, "Add Worker", "Worker"),
                      const SizedBox(height: 10),
                      _buildAddButton(controller, "Add Supervisor", "Supervisor"),
                      const SizedBox(height: 10),
                      _buildAddButton(controller, "Add Management Staff", "Management Staff"),
                      const SizedBox(height: 25),
                    ],

                    // Search bar
                    TextField(
                      controller: controller.searchController,
                      decoration: InputDecoration(
                        hintText: "Search by name or role...",
                        prefixIcon: const Icon(LucideIcons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: controller.primaryBlue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),

              // ✅ User list — SliverList.builder for smooth performance
              if (controller.filteredUsers.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text("No users found.",
                        style:
                        TextStyle(color: Colors.black54, fontSize: 15)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: controller.filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(
                          controller, controller.filteredUsers[index]);
                    },
                  ),
                ),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAddButton(
      ManageUsersController controller, String text, String role) {
    final displayText =
    text.toLowerCase().startsWith("add ") ? text.substring(4) : text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => _navigateToAddPage(controller, role),
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.primaryBlue,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            children: [
              Container(
                height: double.infinity,
                width: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(10)),
                ),
                child: Center(
                    child:
                    Icon(Icons.add, color: controller.primaryBlue, size: 24)),
              ),
              Expanded(
                child: Center(
                  child: Text(displayText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddPage(
      ManageUsersController controller, String role) async {
    Widget page;
    if (role == "Worker") {
      page = const AddWorkerView();
    } else if (role == "Supervisor") {
      page = const AddSupervisorView();
    } else {
      page = const AddManagementStaffView();
    }
    final result = await Get.to(() => page);
    if (result == true) controller.fetchUsers();
  }

  void _navigateToEditPage(
      ManageUsersController controller, User user) async {
    final result = await Get.to(() => EditUserView(user: user));
    if (result == true) controller.fetchUsers();
  }

  Widget _buildUserCard(ManageUsersController controller, User user) {
    final bool isActive = user.isActive;
    final Color cardColor = isActive ? Colors.white : Colors.red.shade50;
    final Color titleColor =
    isActive ? controller.primaryBlue : Colors.red.shade800;
    final Color subtitleColor =
    isActive ? Colors.black54 : Colors.red.shade600;
    final Color iconColor =
    isActive ? controller.primaryBlue : Colors.red.shade700;

    ImageProvider profileImage =
    const AssetImage("assets/images/profile.png");
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      profileImage = NetworkImage(user.profileImageUrl!);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          backgroundImage: profileImage,
        ),
        title: Text(
          user.userId + (isActive ? "" : " (DISABLED)"),
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${user.name} - ${user.role[0].toUpperCase() + user.role.substring(1)}",
          style: TextStyle(color: subtitleColor),
        ),
        trailing: IconButton(
          icon: Icon(LucideIcons.edit3, color: iconColor, size: 20),
          onPressed: () => _navigateToEditPage(controller, user),
        ),
      ),
    );
  }
}