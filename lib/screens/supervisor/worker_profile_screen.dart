// lib/screens/supervisor/worker_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/screens/supervisor/worker_checkin_screen.dart';
import 'package:smartcare_app/screens/supervisor/worker_checkout_screen.dart';
import 'package:smartcare_app/screens/supervisor/worker_submit_complaint_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  final String id; // The MongoDB _id of the worker
  final String name;
  final String userId;

  const WorkerProfileScreen({
    Key? key,
    required this.id, // ✅ Required to link complaints to this specific worker
    required this.name,
    required this.userId,
  }) : super(key: key);

  final Color themeBlue = const Color(0xFF0B3B8C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Worker Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildProfileCard(context),
            const SizedBox(height: 16),
            _buildComplaintCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Worker Profile",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeBlue,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: themeBlue.withOpacity(0.08),
                child: Icon(Icons.person, color: themeBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userId,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkerCheckInScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_outlined),
                  label: const Text("Check-In"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkerCheckOutScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text("Check-Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Submit Complaint",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "If the worker has any issue related to work, safety or attendance, "
            "you can submit a complaint on their behalf.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // ✅ PASSING THE ID to the submit screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerSubmitComplaintScreen(
                      workerMongoId: id, // Passing the MongoDB ID
                      name: name,
                      userId: userId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text("Submit Complaint"),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}