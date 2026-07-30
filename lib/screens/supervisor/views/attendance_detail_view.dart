// lib/screens/supervisor/views/attendance_detail_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartcare_app/screens/supervisor/controllers/attendance_detail_controller.dart';

class AttendanceDetailView extends StatelessWidget {
  const AttendanceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // permanent: true keeps this controller (and its search TextField's
    // TextEditingController) alive instead of letting GetX auto-dispose it
    // - see workers_view.dart for the same fix and full rationale.
    final controller = Get.put(AttendanceDetailController(), permanent: true);
    const themeBlue = Color(0xFF0B3B8C);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Attendance Detail',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      // ✅ RefreshIndicator CustomScrollView ke saath properly kaam karta hai
      body: RefreshIndicator(
        onRefresh: controller.fetchAllData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Summary Cards ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                // ✅ Sirf count values reactive hain — poora widget rebuild nahi hoga
                child: Obx(() => Column(
                  children: [
                    Row(children: [
                      _StatCard(
                          title: 'Present',
                          count: '${controller.presentCount.value}',
                          color: Colors.green),
                      const SizedBox(width: 10),
                      _StatCard(
                          title: 'Absent',
                          count: '${controller.absentCount.value}',
                          color: Colors.red),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _StatCard(
                          title: 'Late',
                          count: '${controller.lateCount.value}',
                          color: Colors.orange),
                      const SizedBox(width: 10),
                      _StatCard(
                          title: 'Leave',
                          count: '${controller.leaveCount.value}',
                          color: Colors.blueGrey),
                    ]),
                  ],
                )),
              ),
            ),

            // ── Section Header: Self Attendance ───────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Text(
                  'Self Attendance (Last 30 Days)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: themeBlue),
                ),
              ),
            ),

            // ── Self Attendance List ───────────────────────────────────
            // ✅ SliverList.builder — only visible items render honge
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (controller.selfAttendanceList.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _EmptyBox(text: 'No self attendance records found'),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: controller.selfAttendanceList.length,
                itemBuilder: (_, i) {
                  final record = controller.selfAttendanceList[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _SelfAttendanceCard(
                        record: record, controller: controller),
                  );
                },
              );
            }),

            // ── Section Header: Employee List ──────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Text(
                  'Employee List (Today)',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // ── Search Box ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: controller.employeeSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: themeBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Chips ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Obx(() => Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: controller.selectedEmployeeFilter.value == null,
                      onTap: () => controller.setEmployeeFilter(null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Present',
                      isSelected: controller.selectedEmployeeFilter.value == 'present',
                      onTap: () => controller.setEmployeeFilter('present'),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Absent',
                      isSelected: controller.selectedEmployeeFilter.value == 'absent',
                      onTap: () => controller.setEmployeeFilter('absent'),
                      color: Colors.red,
                    ),
                  ],
                )),
              ),
            ),

            // ── Employee List ──────────────────────────────────────────
            // ✅ SliverList.builder — large lists efficiently render hongi
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              if (controller.filteredEmployeeList.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child:
                    _EmptyBox(text: 'No employee found'),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: controller.filteredEmployeeList.length,
                itemBuilder: (_, i) {
                  final emp = controller.filteredEmployeeList[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _EmployeeTile(emp: emp, themeBlue: themeBlue),
                  );
                },
              );
            }),

            // ── Bottom Padding ─────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title, count;
  final Color color;
  const _StatCard(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 6)
          ],
        ),
        child: Column(children: [
          Text(count,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title),
        ]),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
          child: Text(text,
              style: const TextStyle(color: Colors.black54))),
    );
  }
}

class _SelfAttendanceCard extends StatelessWidget {
  final dynamic record;
  final AttendanceDetailController controller;
  const _SelfAttendanceCard(
      {required this.record, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Expanded(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                record['dateDisplay'] ??
                    controller.formatDate(record['date']),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'In: ${record['checkInTimeDisplay'] ?? controller.formatTime(record['checkInTime'])}  '
                  'Out: ${record['checkOutTimeDisplay'] ?? controller.formatTime(record['checkOutTime'])}',
              style:
              const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ]),
        ),
        _StatusChip(status: record['status'] ?? 'absent'),
      ]),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final dynamic emp;
  final Color themeBlue;
  const _EmployeeTile({required this.emp, required this.themeBlue});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = emp['profileImageUrl'] as String?;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: themeBlue.withValues(alpha: 0.1),
          backgroundImage: hasImage
              ? CachedNetworkImageProvider(imageUrl)
              : null,
          child: !hasImage
              ? Icon(Icons.person, size: 20, color: themeBlue)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp['name'] ?? 'Unknown',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(emp['userId'] ?? '',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ]),
        ),
        _StatusChip(status: emp['status'] ?? 'absent'),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  // ✅ Static const map — har baar switch run nahi hoga
  static const Map<String, Color> _colorMap = {
    'present': Colors.green,
    'absent': Colors.red,
    'late': Colors.orange,
    'leave': Colors.blueGrey,
    'pending': Colors.amber,
  };

  @override
  Widget build(BuildContext context) {
    final Color c = _colorMap[status.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style:
        TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Colors.blue)
              : (color ?? Colors.blue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? Colors.blue)
                : (color ?? Colors.blue).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (color ?? Colors.blue),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}