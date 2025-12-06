// lib/screens/supervisor/worker_overtime_submission_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/screens/supervisor/worker_checkin_screen.dart';
import 'package:smartcare_app/screens/supervisor/worker_checkout_screen.dart';

class WorkerOvertimeSubmissionScreen extends StatefulWidget {
  final String name;
  final String userId;

  const WorkerOvertimeSubmissionScreen({
    Key? key,
    required this.name,
    required this.userId,
  }) : super(key: key);

  @override
  State<WorkerOvertimeSubmissionScreen> createState() =>
      _WorkerOvertimeSubmissionScreenState();
}

class _WorkerOvertimeSubmissionScreenState
    extends State<WorkerOvertimeSubmissionScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);

  String _dateTimeText = "";
  Timer? _timer;


  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startDateTimeTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    final now = DateTime.now();
    final datePart = DateFormat('EEE, dd MMM yyyy').format(now);
    final timePart = DateFormat('hh:mm:ss a').format(now);
    setState(() {
      _dateTimeText = "$datePart  $timePart";
    });
  }


  void _submitOvertime() async {

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        title: const Text(
          "Overtime Submission",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
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
            // DATE & TIME (real-time)
            const Text(
              "Date & Time",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            _buildInfoField(
              icon: Icons.calendar_today_outlined,
              text: _dateTimeText.isEmpty ? "Loading..." : _dateTimeText,
            ),
            const SizedBox(height: 18),

            // WORKER NAME
            const Text(
              "Worker Name",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            _buildInfoField(
              icon: Icons.person_outline,
              text: widget.name,
            ),
            const SizedBox(height: 18),

            // WORKER ID
            const Text(
              "Worker ID",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            _buildInfoField(
              icon: Icons.badge_outlined,
              text: widget.userId,
            ),
            const SizedBox(height: 18),

            // Check-In (left) & Check-Out (right) buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Worker Check-In screen open
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorkerCheckInScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.login_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      "Check-In",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Worker Check-Out screen open
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorkerCheckOutScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.logout_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      "Check-Out",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }


  Widget _buildInfoField({required IconData icon, required String text}) {
    return Container(
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
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
