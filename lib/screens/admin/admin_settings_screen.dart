// lib/screens/admin/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'package:smartcare_app/screens/shared/login_screen.dart';
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightGrey = Colors.grey.shade100;

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _showUserAgreementCard() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SmartNex.Tech Construction Attendance System\nUser Agreement",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Effective Date: December 4, 2025",
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Welcome to the SmartNex.Tech Attendance System (\"The Service\"). "
                    "By accessing or using the Service, you agree to be bound by these "
                    "Terms of Use and all applicable laws and regulations.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),

              // 1. Description of Service
              Text(
                "1. Description of Service",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The Service is a digital attendance and workforce management platform "
                    "provided under contract specifically for use by Ray Engineering personnel "
                    "and their authorized project managers.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                "The Service requires access to your device's Camera, Location (GPS), and "
                    "Internet to function. It utilizes advanced Artificial Intelligence (AI) "
                    "and image processing technology to:",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                "• Image Capture & Verification (Camera/AI): Verify worker identity via "
                    "facial recognition from images captured at sign-in/sign-out using the "
                    "device's camera to feed data to the AI model.\n\n"
                    "• Location Tracking (GPS): Accurately record the time and track the "
                    "geographical location (geofencing) of the user at the point of "
                    "attendance capture using GPS.\n\n"
                    "• Data Management (Internet/Reporting): Provide real-time data to "
                    "authorized project managers for payroll and compliance purposes, and "
                    "facilitate the export and storage of attendance reports.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 14),
              Text(
                "1.1 Relationship to Privacy Policy",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "This User Agreement incorporates by reference the SmartNex.Tech Privacy Policy, "
                    "which is available at:\n"
                    "https://public-document.smartnex.tech/ray-enginerring/attainadnace-app/privacy-policy-playstore\n\n"
                    "By agreeing to these Terms, you also acknowledge that you have read and "
                    "understood our Privacy Policy, which governs the collection, use, and "
                    "protection of your personal and sensitive data, including biometric and "
                    "location data.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 16),
              Text(
                "2. User Obligations",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "As a user (either as a Worker or a Project Manager) employed by or contracted "
                    "with Ray Engineering, you agree to:",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 6),
              const Text(
                "• Accurate Data: Provide true, accurate, current, and complete information "
                    "during the registration process.\n\n"
                    "• Biometric Consent: Consent to the capture and processing of your image/"
                    "face geometry for the sole purpose of identity verification within the "
                    "Service. You understand that this data is considered sensitive and will be "
                    "protected according to our Privacy Policy.\n\n"
                    "• Location Tracking: Consent to the tracking and recording of your device's "
                    "geographical location only at the time of clock-in and clock-out to verify "
                    "on-site presence. Continuous, background location tracking is not performed "
                    "unless explicitly consented to for specific, clearly defined project "
                    "monitoring features.\n\n"
                    "• Proper Use: Use the Service strictly for recording work attendance at "
                    "designated project sites and not for any unauthorized, fraudulent, or illegal "
                    "purposes.\n\n"
                    "• Security: Keep your login credentials confidential and notify SmartNex.Tech "
                    "immediately of any unauthorized use of your account.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 16),
              Text(
                "3. AI and Verification",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You acknowledge that the Service relies on AI models for identity verification. "
                    "While highly accurate, no system is infallible. SmartNex.Tech retains the right "
                    "for Project Managers (including those at Ray Engineering) to manually override "
                    "or confirm attendance records in case of AI-flagged discrepancies, and "
                    "SmartNex.Tech bears no liability for minor, occasional, or technical AI errors.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 16),
              Text(
                "4. Intellectual Property",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "All rights, title, and interest in and to the Service (excluding content provided "
                    "by users) are and will remain the exclusive property of SmartNex.Tech. The software, "
                    "including the AI models and algorithms, is protected by copyright and other "
                    "intellectual property laws.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 16),
              Text(
                "5. Fees and Payment",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Access to and use of the Service is subject to the timely payment of the agreed-upon "
                    "monthly or annual subscription fees (\"Fees\") by Ray Engineering or the contracting entity.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                "• Data Retention Window: SmartNex.Tech guarantees the retention of all client "
                    "attendance and performance data for a period not exceeding three (3) months from "
                    "the date of its collection (\"Active Retention Period\"). Data exceeding this Active "
                    "Retention Period is subject to archival or permanent deletion without prior notice.\n\n"
                    "• Fee Changes: SmartNex.Tech reserves the right to increase the Fees, including "
                    "maintenance fees, upon providing users with at least thirty (30) days' written "
                    "notice prior to the start of the next billing cycle. Continued use of the Service "
                    "after the effective date of the Fee change constitutes acceptance of the new Fees.\n\n"
                    "• Non-Payment and Suspension: Failure to pay the Fees when due constitutes a material "
                    "breach of these Terms. SmartNex.Tech reserves the right, after providing a minimum of "
                    "ten (10) days' notice of delinquency, to immediately suspend or revoke access to the "
                    "Service.\n\n"
                    "• Data Loss upon Revocation: In the event of revocation of service due to non-payment, "
                    "the user acknowledges and agrees that SmartNex.Tech is under no obligation to retain "
                    "any associated attendance and performance data (including data within the Active "
                    "Retention Period), and such data may be permanently deleted and irrecoverable.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 16),
              Text(
                "6. Termination",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "SmartNex.Tech may terminate or suspend your access to the Service immediately, without "
                    "prior notice or liability, if you breach these Terms, including but not limited to "
                    "the non-payment of Fees outlined in Section 5. Upon termination, your right to use "
                    "the Service will immediately cease.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 16),
              Text(
                "7. Disclaimers",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The Service is provided on an \"AS IS\" and \"AS AVAILABLE\" basis. SmartNex.Tech makes no "
                    "warranty that (i) the Service will meet your specific requirements, (ii) the Service will "
                    "be uninterrupted, timely, secure, or error-free, or (iii) the results that may be obtained "
                    "from the use of the Service will be accurate or reliable.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 16),
              Text(
                "8. Governing Law",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "These Terms shall be governed and construed in accordance with the laws of the "
                    "jurisdiction where SmartNex.Tech is headquartered, without regard to its conflict of "
                    "law provisions.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 16),
              const Text(
                "By creating the account, you are agreeing to these Terms of Use.",
                style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(color: primaryBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactCard() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Contact SmartNex.Tech Support\n(Ray Engineering Projects)",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "We are here to assist you with any questions, technical support issues specifically "
                    "related to the Ray Engineering attendance system, or requests regarding your data "
                    "and account.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                "Technical Support & General Inquiries\n(For Ray Engineering Projects)",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Reach out to us through any of these channels. We are here to help and excited to "
                    "discuss your requirements.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
              const Text("• Email: contact@smartnex.tech",
                  style: TextStyle(fontSize: 14)),
              const Text("• Phone: +91 82608 05119",
                  style: TextStyle(fontSize: 14)),
              const Text("• Website: https://www.smartnex.tech/",
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Text(
                "Our Response Commitment",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We strive to respond to all inquiries promptly:",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                "• Phone: Within 1 hour (during business hours)\n"
                    "• Email: Within 24 hours",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                "Support Hours: Monday to Friday, 9:00 AM - 8:00 PM IST",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                "Data Protection Officer (DPO)",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "For inquiries concerning your personal data, biometric data processing, "
                    "or the Privacy Policy:",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 4),
              const Text(
                "• Email: contact@smartnex.tech",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                "Ray Engineering Website Reference",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "For official company information regarding our client: rayengineering.coye",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(color: primaryBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyCard() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SmartNex.Tech Construction Attendance System\nPrivacy Policy",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Effective Date: December 4, 2025",
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              const Text(
                "SmartNex.Tech is committed to protecting the privacy and security of your data. "
                    "This Privacy Policy explains how we collect, use, and protect the unique and "
                    "sensitive information we handle, particularly in the context of construction site "
                    "attendance for Ray Engineering projects.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                "1. Data Collection and Usage",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We collect the following categories of data using your device's Camera, GPS, and "
                    "Internet connectivity for the purposes outlined below:",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
              const Text(
                "Identity Data\n"
                    "Name, Employee ID, Role, Project Assignment.\n"
                    "Purpose: Account management and associating attendance records with the correct "
                    "individual working for Ray Engineering.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
              const Text(
                "Biometric/Image Data\n"
                    "Digital image (photograph) captured at sign-in/out via the device Camera; "
                    "derived facial geometry (template).\n"
                    "Primary Purpose: Secure, non-transferable identity verification using AI. The "
                    "image and template are used solely for comparison and are stored encrypted.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
              const Text(
                "Location Data\n"
                    "GPS Coordinates (Latitude/Longitude), Timestamp.\n"
                    "Primary Purpose: Geofencing validation to confirm the user is physically present "
                    "at the authorized construction site boundary during clock-in/out (using GPS).",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
              const Text(
                "Attendance Data\n"
                    "Time of clock-in, time of clock-out, associated project.\n"
                    "Purpose: Calculating accurate working hours, facilitating report export, and "
                    "generating payroll records for Ray Engineering.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
              const Text(
                "Device Data\n"
                    "Device ID, IP address, operating system.\n"
                    "Purpose: System diagnostics, security, and preventing fraudulent access attempts "
                    "(requires Internet connection).",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                "2. Use of AI and Image Processing",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The core functionality of the Service is built around AI-driven image verification:",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 6),
              const Text(
                "• Verification Process: When a user attempts to clock in or out, an image is "
                    "captured via the Camera. This image is immediately processed by our AI to "
                    "extract a unique facial template (a mathematical representation of the face). "
                    "This template is compared against the user's stored template to confirm identity.\n\n"
                    "• Image Storage: The raw image and the derived template are stored securely using "
                    "industry-standard encryption and access controls. They are used only for identity "
                    "verification and are never used for marketing, sold to third parties, or used for "
                    "any purpose outside of workforce management for Ray Engineering.\n\n"
                    "• Retention: Image and template data are retained only as long as the user is "
                    "actively employed or contracted by Ray Engineering, or as required by regulatory "
                    "retention laws, after which they are securely destroyed.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                "3. Location Tracking Protocol (GPS Usage)",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Our Service adheres to a strict location tracking policy:",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 6),
              const Text(
                "• Ephemeral Tracking: Location data (GPS) is collected and recorded only at the "
                    "precise moment the user clicks the \"Clock In\" or \"Clock Out\" button.\n\n"
                    "• No Continuous Monitoring: The application does not track or record the user's "
                    "location continuously while they are signed in or when the app is running in the "
                    "background.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                "4. Data Security",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We implement robust security measures to protect your data from unauthorized access, "
                    "alteration, disclosure, or destruction:",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 6),
              const Text(
                "• Encryption: All data, especially image and facial template data, is encrypted both "
                    "in transit (using SSL/TLS) and at rest (in the database).\n\n"
                    "• Access Control: Access to raw data and databases is strictly limited to essential "
                    "personnel and is logged and audited regularly.\n\n"
                    "• Regulatory Compliance: We strive to comply with relevant data protection "
                    "regulations applicable to the construction and HR technology sectors.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                "5. Your Rights",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You have the right to request access to, correction of, or deletion of your personal "
                    "data, subject to any legal or contractual obligations we may have to retain certain "
                    "records. Requests can be submitted via the Contact Us details provided in the "
                    "application.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(color: primaryBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildSettingsCard(
              icon: LucideIcons.fileSignature,
              title: "User Agreement",
              subtitle: "Learn about application usage rules.",
              onTap: _showUserAgreementCard,
            ),
            _buildSettingsCard(
              icon: LucideIcons.shieldCheck,
              title: "Privacy & Policy",
              subtitle: "Read how your data is protected.",
              onTap: _showPrivacyCard,
            ),
            _buildSettingsCard(
              icon: LucideIcons.phoneCall,
              title: "Contact Us",
              subtitle: "We are here to help you anytime.",
              onTap: _showContactCard,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(LucideIcons.logOut, color: Colors.white),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent[400],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue[50],
          child: Icon(icon, color: primaryBlue, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey.shade600,
        ),
        onTap: onTap,
      ),
    );
  }
}