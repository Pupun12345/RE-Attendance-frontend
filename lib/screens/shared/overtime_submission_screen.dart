import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:smartcare_app/utils/constants.dart';

class OvertimeSubmissionScreen extends StatefulWidget {
  const OvertimeSubmissionScreen({super.key});

  @override
  State<OvertimeSubmissionScreen> createState() =>
      _OvertimeSubmissionScreenState();
}

class _OvertimeSubmissionScreenState extends State<OvertimeSubmissionScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);

  // --- IMPORTANT ---
  // Make sure this is the same IP address you used in the login screen
  //final String _apiUrl = "http://10.5.114.51:5000"; // <-- REPLACE WITH YOUR IP
  final String _apiUrl = apiBaseUrl;

  // State variables
  DateTime? _selectedDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  final TextEditingController reasonController = TextEditingController();
  bool _isLoading = false;

  // ✅ INIT: default date = today
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // yahi se aaj ki date auto select ho jayegi
  }

  // --- Pickers ---

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
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _fromTime = picked);
    }
  }

  Future<void> _pickToTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _toTime = picked);
    }
  }

  // --- Submit Logic ---

  Future<void> _submitOvertime() async {
    // 1. Validation
    if (_selectedDate == null ||
        _fromTime == null ||
        _toTime == null ||
        reasonController.text.isEmpty) {
      _showError("All fields are required.");
      return;
    }

    // 2. Combine Date and Time
    final DateTime startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _fromTime!.hour,
      _fromTime!.minute,
    );
    DateTime endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _toTime!.hour,
      _toTime!.minute,
    );

    // --- LOGIC FOR OVERNIGHT SHIFTS ---
    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      // This detects an overnight shift (e.g., 10pm to 2am)
      // and adds one day to the end time.
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    // 3. Calculate Hours
    final Duration difference = endDateTime.difference(startDateTime);
    final double hours = difference.inMinutes / 60.0;

    // Add a sanity check for shifts that are too long
    if (hours > 24) {
      _showError("Overtime shift cannot exceed 24 hours.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("$_apiUrl/api/v1/overtime"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'date': _selectedDate!.toIso8601String(), // Send the *start* date
          'hours': hours, // Send calculated hours
          'reason': reasonController.text, // Send the reason
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _showSuccess("Overtime request submitted!");
        Navigator.pop(context);
      } else {
        _showError(responseData['message'] ?? "Failed to submit request.");
      }
    } catch (e) {
      _showError("Could not connect to server. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Overtime Submission",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Date Picker ---
            const Text("Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildPickerField(
              text: _selectedDate == null
                  ? "Select Date"
                  : DateFormat('EEE, dd MMM yyyy').format(_selectedDate!),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),

            // --- From Time Picker ---
            const SizedBox(height: 20),
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

            // --- To Time Picker ---
            const SizedBox(height: 20),
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

            // --- Reason Field ---
            const SizedBox(height: 20),
            const Text("Reason for Overtime",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your overtime reason...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            // --- Submit Button ---
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitOvertime,
                icon: _isLoading
                    ? Container()
                    : const Icon(Icons.send, color: Colors.white),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Submit Overtime",
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
          ],
        ),
      ),
    );
  }

  // Helper widget for the picker fields
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
            Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
