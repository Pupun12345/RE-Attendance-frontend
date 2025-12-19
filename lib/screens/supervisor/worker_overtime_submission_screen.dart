import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';


import 'package:smartcare_app/screens/supervisor/worker_checkin_screen.dart';
import 'package:smartcare_app/screens/supervisor/worker_checkout_screen.dart';

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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


  void _submitOvertime() async {
    // backend untouched as requested
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
            // DATE & TIME
            const Text("Date & Time",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildInfoField(
              icon: Icons.calendar_today_outlined,
              text: _dateTimeText.isEmpty ? "Loading..." : _dateTimeText,
            ),

            const SizedBox(height: 18),

            // WORKER NAME
            const Text("Worker Name",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildInfoField(
              icon: Icons.person_outline,
              text: widget.name,
            ),

            const SizedBox(height: 18),

            // WORKER ID
            const Text("Worker ID",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildInfoField(
              icon: Icons.badge_outlined,
              text: widget.userId,
            ),

            const SizedBox(height: 18),

            // HOURS
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

            // REASON
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


            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerCheckInScreen(
                              workerName: widget.name,
                              workerId: widget.userId,
                              workerDbId: widget.dbId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login_outlined,
                          color: Colors.white),
                      label: const Text("Check-In",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerCheckOutScreen(
                              workerName: widget.name,
                              workerId: widget.userId,
                              workerDbId: widget.dbId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_outlined,
                          color: Colors.white),
                      label: const Text("Check-Out",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
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
            child: Text(text,
                style:
                const TextStyle(fontSize: 15, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}