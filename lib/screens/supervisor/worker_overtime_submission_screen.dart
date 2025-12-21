import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

class WorkerOvertimeSubmissionScreen extends StatefulWidget {
  final String name;
  final String userId;
  final String dbId;

  const WorkerOvertimeSubmissionScreen({
    Key? key,
    required this.name,
    required this.userId,
    required this.dbId,
  }) : super(key: key);

  @override
  State<WorkerOvertimeSubmissionScreen> createState() =>
      _WorkerOvertimeSubmissionScreenState();
}

class _WorkerOvertimeSubmissionScreenState
    extends State<WorkerOvertimeSubmissionScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);

  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  String _dateTimeText = "";
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startDateTimeTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hoursController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _startDateTimeTicker() {
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _dateTimeText =
      "${DateFormat('EEE, dd MMM yyyy').format(now)}  ${DateFormat('hh:mm:ss a').format(now)}";
    });
  }

  // ---------------- SUBMIT OVERTIME ----------------
  Future<void> _submitOvertime() async {
    if (_hoursController.text.trim().isEmpty ||
        _reasonController.text.trim().isEmpty) {
      _showSnack("Please enter hours and reason");
      return;
    }

    final double? hours = double.tryParse(_hoursController.text);
    if (hours == null || hours <= 0) {
      _showSnack("Enter valid overtime hours");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final designation = prefs.getString('designation') ?? "Worker";

      if (token == null) {
        _showSnack("Authentication error. Login again.");
        return;
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/overtime'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "date": DateTime.now().toIso8601String(),
          "hours": hours,
          "reason": _reasonController.text.trim(),
          "workerId": widget.dbId,
          "designation": designation, // ✅ ADMIN KO DIKHNE KE LIYE
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
      if (mounted) setState(() => _isSubmitting = false);
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
          "Overtime Submission",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info("Date & Time", Icons.calendar_today_outlined, _dateTimeText),
            _info("Worker Name", Icons.person_outline, widget.name),
            _info("Worker ID", Icons.badge_outlined, widget.userId),

            const SizedBox(height: 18),

            const Text("Hours Worked",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g. 2.5",
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 18),

            const Text("Reason",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Reason for overtime...",
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 28),

            // ✅ SUBMIT OVERTIME BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOvertime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Submit Overtime",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, IconData icon, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.black87)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
