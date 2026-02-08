// lib/screens/shared/login_screen.dart
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ --- FIXED IMPORTS ---
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:smartcare_app/screens/management/management_dashboard_screen.dart';
import 'package:smartcare_app/utils/constants.dart';
// ✅ --- END OF FIX ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  bool _acceptedTerms = false;

  final Color primaryBlue = const Color(0xFF0D47A1);

  // USER AGREEMENT TEXT
  static const String _userAgreementText = '''
SmartNex.Tech Construction Attendance System User Agreement
Effective Date: December 4, 2025

Welcome to the SmartNex.Tech Attendance System ("The Service"). By accessing or using the Service, you agree to be bound by these Terms of Use and all applicable laws and regulations.

1. Description of Service
The Service is a digital attendance and workforce management platform provided under contract specifically for use by Ray Engineering personnel and their authorized project managers.

The Service requires access to your device's Camera, Location (GPS), and Internet to function. It utilizes advanced Artificial Intelligence (AI) and image processing technology to:
• Image Capture & Verification (Camera/AI): Verify worker identity via facial recognition from images captured at sign-in/sign-out using the device's camera to feed data to the AI model.
• Location Tracking (GPS): Accurately record the time and track the geographical location (geofencing) of the user at the point of attendance capture using GPS.
• Data Management (Internet/Reporting): Provide real-time data to authorized project managers for payroll and compliance purposes, and facilitate the export and storage of attendance reports.

1.1 Relationship to Privacy Policy
This User Agreement incorporates by reference the SmartNex.Tech Privacy Policy, which is available at:
https://public-document.smartnex.tech/ray-enginerring/attainadnace-app/privacy-policy-playstore

By agreeing to these Terms, you also acknowledge that you have read and understood our Privacy Policy, which governs the collection, use, and protection of your personal and sensitive data, including biometric and location data.

2. User Obligations
As a user (either as a Worker or a Project Manager) employed by or contracted with Ray Engineering, you agree to:
• Accurate Data: Provide true, accurate, current, and complete information during the registration process.
• Biometric Consent: Consent to the capture and processing of your image/face geometry for the sole purpose of identity verification within the Service. You understand that this data is considered sensitive and will be protected according to our Privacy Policy.
• Location Tracking: Consent to the tracking and recording of your device's geographical location only at the time of clock-in and clock-out to verify on-site presence. Continuous, background location tracking is not performed unless explicitly consented to for specific, clearly defined project monitoring features.
• Proper Use: Use the Service strictly for recording work attendance at designated project sites and not for any unauthorized, fraudulent, or illegal purposes.
• Security: Keep your login credentials confidential and notify SmartNex.Tech immediately of any unauthorized use of your account.

3. AI and Verification
You acknowledge that the Service relies on AI models for identity verification. While highly accurate, no system is infallible. SmartNex.Tech retains the right for Project Managers (including those at Ray Engineering) to manually override or confirm attendance records in case of AI-flagged discrepancies, and SmartNex.Tech bears no liability for minor, occasional, or technical AI errors.

4. Intellectual Property
All rights, title, and interest in and to the Service (excluding content provided by users) are and will remain the exclusive property of SmartNex.Tech. The software, including the AI models and algorithms, is protected by copyright and other intellectual property laws.

5. Fees and Payment
Access to and use of the Service is subject to the timely payment of the agreed-upon monthly or annual subscription fees ("Fees") by Ray Engineering or the contracting entity.

• Data Retention Window: SmartNex.Tech guarantees the retention of all client attendance and performance data for a period not exceeding three (3) months from the date of its collection ("Active Retention Period"). Data exceeding this Active Retention Period is subject to archival or permanent deletion without prior notice.
• Fee Changes: SmartNex.Tech reserves the right to increase the Fees, including maintenance fees, upon providing users with at least thirty (30) days' written notice prior to the start of the next billing cycle. Continued use of the Service after the effective date of the Fee change constitutes acceptance of the new Fees.
• Non-Payment and Suspension: Failure to pay the Fees when due constitutes a material breach of these Terms. SmartNex.Tech reserves the right, after providing a minimum of ten (10) days' notice of delinquency, to immediately suspend or revoke access to the Service.
• Data Loss upon Revocation: In the event of revocation of service due to non-payment, the user acknowledges and agrees that SmartNex.Tech is under no obligation to retain any associated attendance and performance data (including data within the Active Retention Period), and such data may be permanently deleted and irrecoverable.

6. Termination
SmartNex.Tech may terminate or suspend your access to the Service immediately, without prior notice or liability, if you breach these Terms, including but not limited to the non-payment of Fees outlined in Section 5. Upon termination, your right to use the Service will immediately cease.

7. Disclaimers
The Service is provided on an "AS IS" and "AS AVAILABLE" basis. SmartNex.Tech makes no warranty that (i) the Service will meet your specific requirements, (ii) the Service will be uninterrupted, timely, secure, or error-free, or (iii) the results that may be obtained from the use of the Service will be accurate or reliable.

8. Governing Law
These Terms shall be governed and construed in accordance with the laws of the jurisdiction where SmartNex.Tech is headquartered, without regard to its conflict of law provisions.

By creating the account, you are agreeing to these Terms of Use.
''';

  // PRIVACY POLICY TEXT
  static const String _privacyPolicyText = '''
SmartNex.Tech Construction Attendance System Privacy Policy
Effective Date: December 4, 2025

SmartNex.Tech is committed to protecting the privacy and security of your data. This Privacy Policy explains how we collect, use, and protect the unique and sensitive information we handle, particularly in the context of construction site attendance for Ray Engineering projects.

1. Data Collection and Usage
We collect the following categories of data using your device's Camera, GPS, and Internet connectivity for the purposes outlined below:

Identity Data
• Specific Data Points: Name, Employee ID, Role, Project Assignment.
• Purpose of Collection: Account management and associating attendance records with the correct individual working for Ray Engineering.

Biometric/Image Data
• Specific Data Points: Digital image (photograph) captured at sign-in/out via the device Camera; derived facial geometry (template).
• Primary Purpose: Secure, non-transferable identity verification using AI. The image and template are used solely for comparison and are stored encrypted.

Location Data
• Specific Data Points: GPS Coordinates (Latitude/Longitude), Timestamp.
• Primary Purpose: Geofencing validation to confirm the user is physically present at the authorized construction site boundary during clock-in/out (using GPS).

Attendance Data
• Specific Data Points: Time of clock-in, time of clock-out, associated project.
• Purpose of Collection: Calculating accurate working hours, facilitating report export, and generating payroll records for Ray Engineering.

Device Data
• Specific Data Points: Device ID, IP address, operating system.
• Purpose of Collection: System diagnostics, security, and preventing fraudulent access attempts (requires Internet connection).

2. Use of AI and Image Processing
The core functionality of the Service is built around AI-driven image verification:
• Verification Process: When a user attempts to clock in or out, an image is captured via the Camera. This image is immediately processed by our AI to extract a unique facial template (a mathematical representation of the face). This template is compared against the user's stored template to confirm identity.
• Image Storage: The raw image and the derived template are stored securely using industry-standard encryption and access controls. They are used only for identity verification and are never used for marketing, sold to third parties, or used for any purpose outside of workforce management for Ray Engineering.
• Retention: Image and template data are retained only as long as the user is actively employed or contracted by Ray Engineering, or as required by regulatory retention laws, after which they are securely destroyed.

3. Location Tracking Protocol (GPS Usage)
Our Service adheres to a strict location tracking policy:
• Ephemeral Tracking: Location data (GPS) is collected and recorded only at the precise moment the user clicks the "Clock In" or "Clock Out" button.
• No Continuous Monitoring: The application does not track or record the user's location continuously while they are signed in or when the app is running in the background.

4. Data Security
We implement robust security measures to protect your data from unauthorized access, alteration, disclosure, or destruction:
• Encryption: All data, especially image and facial template data, is encrypted both in transit (using SSL/TLS) and at rest (in the database).
• Access Control: Access to raw data and databases is strictly limited to essential personnel and is logged and audited regularly.
• Regulatory Compliance: We strive to comply with relevant data protection regulations applicable to the construction and HR technology sectors.

5. Your Rights
You have the right to request access to, correction of, or deletion of your personal data, subject to any legal or contractual obligations we may have to retain certain records. Requests can be submitted via the Contact Us details provided in the application.
''';

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please enter email and password.");
      return;
    }

    if (!_acceptedTerms) {
      _showError("Please accept Terms & Privacy to continue.");
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        final user = data['user'];
        final String role = user['role'];

        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(user));
        await prefs.setString('userName', user['name']);
        await prefs.setString('role', user['role']);

        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen()),
          );
        } else if (role == 'supervisor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const SupervisorDashboardScreen()),
          );
        } else if (role == 'management') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ManagementDashboardScreen(),
            ),
          );
        } else {
          _showError("Your role is not authorized to log in.");
          setState(() => _isLoggingIn = false);
        }
      } else {
        _showError(data['message'] ?? 'Invalid credentials.');
        setState(() => _isLoggingIn = false);
      }
    } catch (e) {
      _showError("Could not connect to server. Check your API URL.");
      setState(() => _isLoggingIn = false);
    }
  }

  void _handleForgotPassword(String email) async {
    if (email.isEmpty) return;
    final url = Uri.parse('$apiBaseUrl/api/v1/auth/forgotpassword');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor:
            data['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError("Server error. Could not send reset link.");
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Forgot Password"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: "Enter your registered email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () =>
                _handleForgotPassword(emailController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _showUserAgreementDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("User Agreement"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              _userAgreementText,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              _privacyPolicyText,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canLogin = !_isLoggingIn && _acceptedTerms;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Login",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 180,
                child: Lottie.asset(
                  "assets/lottie/admin_login.json",
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Accurate attendance. Anytime. Anywhere.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email or User ID",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: primaryBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Terms & Privacy row with links (alignment fixed)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: primaryBlue,
                    onChanged: (val) {
                      setState(() {
                        _acceptedTerms = val ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(
                            text: "I agree to the ",
                          ),
                          TextSpan(
                            text: "Terms",
                            style: TextStyle(
                              color: primaryBlue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _showUserAgreementDialog,
                          ),
                          const TextSpan(
                            text: " and ",
                          ),
                          TextSpan(
                            text: "Privacy",
                            style: TextStyle(
                              color: primaryBlue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _showPrivacyPolicyDialog,
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canLogin ? _handleLogin : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoggingIn
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Login",
                    style:
                    TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _showForgotPasswordDialog(context),
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}