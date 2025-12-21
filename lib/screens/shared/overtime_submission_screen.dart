import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:smartcare_app/utils/constants.dart';

class OvertimeSubmissionScreen extends StatefulWidget {
  const OvertimeSubmissionScreen({super.key});

  @override
  State<OvertimeSubmissionScreen> createState() =>
      _OvertimeSubmissionScreenState();
}

class _OvertimeSubmissionScreenState extends State<OvertimeSubmissionScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  final TextEditingController reasonController = TextEditingController();
  bool _isSubmitting = false;

  // ---------------- DATE PICKER ----------------
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ---------------- TIME PICKERS ----------------
  Future<void> _pickFromTime() async {
    final TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _fromTime = picked);
  }

  Future<void> _pickToTime() async {
    final TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _toTime = picked);
  }

  // ---------------- SUBMIT OVERTIME (ADMIN API) ----------------
  Future<void> _submitOvertime() async {
    if (_fromTime == null || _toTime == null) {
      _showSnack("Please select From Time and To Time");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _showSnack("Authentication error. Please login again.");
        return;
      }

      final fromDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _fromTime!.hour,
        _fromTime!.minute,
      );

      final toDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _toTime!.hour,
        _toTime!.minute,
      );

      final duration = toDateTime.difference(fromDateTime);
      final double totalHours = duration.inMinutes / 60;

      if (totalHours <= 0) {
        _showSnack("Invalid time selection");
        return;
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/overtime'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "date": _selectedDate.toIso8601String(),
          "hours": totalHours,
          "reason": reasonController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _showSnack("Overtime submitted successfully", success: true);
        Navigator.pop(context);
      } else {
        _showSnack(data['message'] ?? "Submission failed");
      }
    } catch (e) {
      _showSnack("Something went wrong");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
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
            _title("Date"),
            _pickerField(
              DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
              Icons.calendar_today_outlined,
              _pickDate,
            ),

            const SizedBox(height: 20),

            _title("From Time"),
            _pickerField(
              _fromTime == null ? "Select From Time" : _fromTime!.format(context),
              Icons.access_time,
              _pickFromTime,
            ),

            const SizedBox(height: 20),

            _title("To Time"),
            _pickerField(
              _toTime == null ? "Select To Time" : _toTime!.format(context),
              Icons.access_time,
              _pickToTime,
            ),

            const SizedBox(height: 20),

            _title("Reason"),
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

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOvertime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Submit Overtime",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _title(String text) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  Widget _pickerField(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
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
