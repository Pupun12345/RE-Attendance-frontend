// lib/screens/admin/views/admin_holiday_setup_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_holiday_setup_controller.dart';

class AdminHolidaySetupView extends StatelessWidget {
  const AdminHolidaySetupView({super.key});

  static const _blue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminHolidaySetupController());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _blue),
          onPressed: () => Get.back(),
        ),
        title: const Text('Holiday Setup',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(LucideIcons.bell, color: _blue),
              onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundImage: const AssetImage('assets/images/profile.png'),
              radius: 18,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Company Holidays',
              style: TextStyle(
                  color: _blue, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          // ── Holiday List ──────────────────────────────────
          Obx(() {
            if (c.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: _blue));
            }
            if (c.holidays.isEmpty) {
              return const Center(
                  child: Text('No holidays added yet.',
                      style: TextStyle(color: Colors.black54)));
            }
            return Column(
              children: c.holidays
                  .map((h) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[50],
                            child: const Icon(LucideIcons.calendar, color: _blue),
                          ),
                          title: Text(h.formattedDate,
                              style: const TextStyle(
                                  color: _blue, fontWeight: FontWeight.bold)),
                          subtitle: Text(h.name,
                              style:
                                  const TextStyle(color: Colors.black54)),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.trash2,
                                color: Colors.redAccent),
                            onPressed: () => c.deleteHoliday(h.id),
                          ),
                        ),
                      ))
                  .toList(),
            );
          }),

          const SizedBox(height: 20),

          // ── Toggle Button ─────────────────────────────────
          Obx(() => OutlinedButton.icon(
                onPressed: c.toggleForm,
                icon: Icon(
                    c.showForm.value
                        ? LucideIcons.x
                        : LucideIcons.calendarDays,
                    color: _blue),
                label:
                    Text(c.showForm.value ? 'Cancel' : 'Add New Holiday'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: const BorderSide(color: _blue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              )),

          // ── Add Form ──────────────────────────────────────
          Obx(() => c.showForm.value
              ? Card(
                  margin: const EdgeInsets.only(top: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          TextFormField(
                            controller: c.nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Holiday Name',
                              labelStyle: TextStyle(color: _blue),
                              icon: Icon(LucideIcons.calendar, color: _blue),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: _blue)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Type Dropdown
                          Obx(() => DropdownButtonFormField<String>(
                                value: c.selectedType.value,
                                decoration: const InputDecoration(
                                  labelText: 'Holiday Type',
                                  labelStyle: TextStyle(color: _blue),
                                  icon: Icon(LucideIcons.tag, color: _blue),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: _blue)),
                                ),
                                items: ['company', 'national']
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t[0].toUpperCase() +
                                              t.substring(1)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) c.selectedType.value = v;
                                },
                              )),
                          const SizedBox(height: 20),

                          // Date Picker
                          Row(children: [
                            const Icon(LucideIcons.clock, color: _blue),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Obx(() => InkWell(
                                    onTap: () => c.pickDate(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        c.selectedDate.value == null
                                            ? 'Select Date'
                                            : Holiday(
                                                id: '',
                                                name: '',
                                                date: c.selectedDate.value!,
                                                type: '',
                                              ).formattedDate,
                                        style: TextStyle(
                                          color: c.selectedDate.value == null
                                              ? Colors.black54
                                              : _blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: c.saveHoliday,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Save Holiday',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ]),
                  ),
                )
              : const SizedBox.shrink()),
        ]),
      ),
    );
  }
}
