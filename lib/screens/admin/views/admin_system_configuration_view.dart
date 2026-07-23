// lib/screens/admin/views/admin_system_configuration_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_system_configuration_controller.dart';

class AdminSystemConfigurationView extends StatelessWidget {
  const AdminSystemConfigurationView({super.key});

  static const _blue      = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminSystemConfigurationController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            backgroundImage: const AssetImage('assets/images/profile.png'),
            radius: 18,
            backgroundColor: Colors.grey[300],
          ),
        ),
        title: const Text('System Configuration',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(LucideIcons.bell, color: _blue),
              onPressed: () {}),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _sectionTitle('Company Information'),
            _textField(c.companyNameCtrl, 'Company Name'),
            const SizedBox(height: 12),
            _textField(c.emailCtrl, 'Company Email'),
            const SizedBox(height: 12),
            _textField(c.contactCtrl, 'Contact Number'),
            const SizedBox(height: 12),
            _textField(c.locationCtrl, 'Company Location'),
            const SizedBox(height: 24),

            _sectionTitle('Attendance Settings'),
            _TimeCard(c: c),
            const SizedBox(height: 12),

            Obx(() => _switchCard('Enable Overtime',        c.overtimeEnabled.value,    (v) => c.overtimeEnabled.value = v)),
            Obx(() => _switchCard('Auto Attendance Lock',   c.autoLockAttendance.value, (v) => c.autoLockAttendance.value = v)),
            const SizedBox(height: 24),

            _sectionTitle('System Preferences'),
            Obx(() => _switchCard('Dark Mode',              c.darkMode.value,             (v) => c.darkMode.value = v)),
            Obx(() => _switchCard('Enable Notifications',   c.notificationsEnabled.value, (v) => c.notificationsEnabled.value = v)),
            _DropdownCard(c: c),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: c.saveConfig,
                icon: const Icon(LucideIcons.save, color: Colors.white),
                label: const Text('Save Configuration',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _sectionTitle(String title) => Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: _blue, fontSize: 16)),
      );

  Widget _textField(TextEditingController ctrl, String label) =>
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _blue),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _blue, width: 2),
              borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      );

  Widget _switchCard(String title, bool value, Function(bool) onChange) =>
      Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: const Icon(LucideIcons.settings, color: _blue),
          title: Text(title,
              style: const TextStyle(
                  color: _blue, fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: Switch(
              activeColor: _blue, value: value, onChanged: onChange),
        ),
      );
}

// ─── Time Card ─────────────────────────────────────────────────────────────

class _TimeCard extends StatelessWidget {
  final AdminSystemConfigurationController c;
  static const _blue      = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);

  const _TimeCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => _timeTile(context, 'Start Time', c.startTime.value, true)),
              Obx(() => _timeTile(context, 'End Time',   c.endTime.value,   false)),
            ]),
      ),
    );
  }

  Widget _timeTile(
      BuildContext context, String label, TimeOfDay time, bool isStart) {
    return GestureDetector(
      onTap: () => c.pickTime(context, isStart),
      child: Column(children: [
        Text(label,
            style: const TextStyle(
                color: _blue, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(10)),
          child: Text(time.format(context),
              style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      ]),
    );
  }
}

// ─── Dropdown Card ─────────────────────────────────────────────────────────

class _DropdownCard extends StatelessWidget {
  final AdminSystemConfigurationController c;
  static const _blue = Color(0xFF0D47A1);

  const _DropdownCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(LucideIcons.database, color: _blue),
        title: const Text('Backup Frequency',
            style: TextStyle(
                color: _blue, fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Obx(() => DropdownButton<String>(
              value: c.backupFrequency.value,
              underline: const SizedBox(),
              onChanged: (v) {
                if (v != null) c.backupFrequency.value = v;
              },
              items: ['Daily', 'Weekly', 'Monthly']
                  .map((v) => DropdownMenuItem(
                      value: v,
                      child:
                          Text(v, style: const TextStyle(fontSize: 14))))
                  .toList(),
            )),
      ),
    );
  }
}
