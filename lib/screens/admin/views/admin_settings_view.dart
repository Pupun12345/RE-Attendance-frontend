// lib/screens/admin/views/admin_settings_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/admin/controllers/admin_settings_controller.dart';

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  static const _blue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminSettingsController());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(LucideIcons.bell, color: Colors.white),
              onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 10),
          _SettingsCard(
            icon: LucideIcons.fileSignature,
            title: 'User Agreement',
            subtitle: 'Learn about application usage rules.',
            onTap: () => _showUserAgreement(context),
          ),
          _SettingsCard(
            icon: LucideIcons.shieldCheck,
            title: 'Privacy & Policy',
            subtitle: 'Read how your data is protected.',
            onTap: () => _showPrivacy(context),
          ),
          _SettingsCard(
            icon: LucideIcons.phoneCall,
            title: 'Contact Us',
            subtitle: 'We are here to help you anytime.',
            onTap: () => _showContact(context),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: c.logout,
              icon: const Icon(LucideIcons.logOut, color: Colors.white),
              label: const Text('Log Out',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent[400],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────

  void _showUserAgreement(BuildContext ctx) =>
      _showInfoDialog(ctx, 'User Agreement', _userAgreementContent);

  void _showPrivacy(BuildContext ctx) =>
      _showInfoDialog(ctx, 'Privacy & Policy', _privacyContent);

  void _showContact(BuildContext ctx) =>
      _showInfoDialog(ctx, 'Contact Us', _contactContent);

  void _showInfoDialog(BuildContext ctx, String title, String content) {
    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _blue, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close', style: TextStyle(color: _blue)),
            ),
          ),
        ]),
      ),
    ));
  }

  // ── Static Content ─────────────────────────────────────────────────────

  static const _userAgreementContent = '''SmartNex.Tech Construction Attendance System — User Agreement

Effective Date: December 4, 2025

Welcome to the SmartNex.Tech Attendance System ("The Service"). By accessing or using the Service, you agree to be bound by these Terms of Use and all applicable laws and regulations.

1. Description of Service
The Service is a digital attendance and workforce management platform provided under contract specifically for use by Ray Engineering personnel and their authorized project managers.

2. User Obligations
As a user you agree to provide accurate data, consent to biometric capture for identity verification, consent to location tracking at clock-in/out, and use the Service strictly for recording work attendance.

3. AI and Verification
The Service relies on AI models for identity verification. SmartNex.Tech bears no liability for minor AI errors.

4. Intellectual Property
All rights, title, and interest in and to the Service are the exclusive property of SmartNex.Tech.

5. Fees and Payment
Access is subject to timely payment of agreed fees. Data retention is guaranteed for 3 months. Non-payment may result in service suspension.

6. Termination
SmartNex.Tech may terminate access immediately for breach of these Terms.

7. Disclaimers
The Service is provided "AS IS" and "AS AVAILABLE".

8. Governing Law
These Terms are governed by the laws of SmartNex.Tech's jurisdiction.

By creating the account, you are agreeing to these Terms of Use.''';

  static const _privacyContent = '''SmartNex.Tech Construction Attendance System — Privacy Policy

Effective Date: December 4, 2025

We collect: Identity Data, Biometric/Image Data (camera), Location Data (GPS at clock-in/out only), Attendance Data, and Device Data.

Location Tracking: GPS is collected only at the moment you click "Clock In" or "Clock Out". No continuous background tracking.

Data Security: All data is encrypted in transit (SSL/TLS) and at rest. Access is strictly controlled.

Your Rights: You may request access, correction, or deletion of your personal data via contact@smartnex.tech.''';

  static const _contactContent = '''SmartNex.Tech Support — Ray Engineering Projects

Email: contact@smartnex.tech
Phone: +91 82608 05119
Website: https://www.smartnex.tech/

Support Hours: Monday–Friday, 9:00 AM–8:00 PM IST
Response: Phone within 1 hr, Email within 24 hrs.

Data Protection Officer: contact@smartnex.tech
Ray Engineering: rayengineering.coye''';
}

// ─── Settings Card ─────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SettingsCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  static const _blue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue[50],
          child: Icon(icon, color: _blue, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                color: _blue, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle:
            Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 18, color: Colors.grey.shade600),
        onTap: onTap,
      ),
    );
  }
}
