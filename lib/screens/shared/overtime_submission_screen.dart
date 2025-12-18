import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/shared/selfie_checkin_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkout_screen.dart';

class OvertimeSubmissionScreen extends StatefulWidget {
  const OvertimeSubmissionScreen({super.key});

  @override
  State<OvertimeSubmissionScreen> createState() =>
      _OvertimeSubmissionScreenState();
}

class _OvertimeSubmissionScreenState extends State<OvertimeSubmissionScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  final String _apiUrl = apiBaseUrl;

  DateTime? _selectedDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  final TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  // ---------------- PICKERS ----------------

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickFromTime() async {
    TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _fromTime = picked);
  }

  Future<void> _pickToTime() async {
    TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _toTime = picked);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        title: const Text(
          "Overtime",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DATE
            const Text("Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildPickerField(
              text: DateFormat('EEE, dd MMM yyyy').format(_selectedDate!),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),

            const SizedBox(height: 20),

            // FROM TIME
            const Text("From Time",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildPickerField(
              text: _fromTime == null
                  ? "Select From Time"
                  : _fromTime!.format(context),
              icon: Icons.access_time,
              onTap: _pickFromTime,
            ),

            const SizedBox(height: 20),

            // TO TIME
            const Text("To Time",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildPickerField(
              text: _toTime == null
                  ? "Select To Time"
                  : _toTime!.format(context),
              icon: Icons.access_time,
              onTap: _pickToTime,
            ),

            const SizedBox(height: 20),

            // REASON
            const Text("Reason",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter reason...",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            // ✅ CHECK-IN / CHECK-OUT BUTTONS
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SelfieCheckInScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text(
                        "Check In",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SelfieCheckOutScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Check Out",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- COMMON PICKER UI ----------------
  Widget _buildPickerField({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}