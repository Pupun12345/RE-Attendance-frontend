// lib/screens/supervisor/worker_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/screens/supervisor/worker_checkin_screen.dart';
import 'package:smartcare_app/screens/supervisor/worker_checkout_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  final String name;
  final String userDisplayId; // e.g. UMS1402
  final String workerId;      // e.g. 674dd... (Database ID)

  const WorkerProfileScreen({
    Key? key,
    required this.name,
    required this.userDisplayId,
    required this.workerId, // ✅ Required for API calls
  }) : super(key: key);

  final Color themeBlue = const Color(0xFF0B3B8C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0B3B8C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Worker Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: themeBlue,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildProfileCard(context),
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
          const SizedBox(height: 2),
          Text(
            "Worker Profile",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // Name & ID row
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
                      style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userDisplayId,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                    // Navigate to check-in screen with worker ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkerCheckInScreen(
                          workerId: workerId, 
                          workerName: name,
                        ),
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
                    // Navigate to check-out screen with worker ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkerCheckOutScreen(
                          workerId: workerId, 
                          workerName: name,
                        ),
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
}