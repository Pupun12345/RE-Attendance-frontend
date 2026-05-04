import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'login_controller.dart';

// ── User Agreement & Privacy texts ──────────────────────────────────────────
const _userAgreementText = '''
SmartNex.Tech Construction Attendance System User Agreement
Effective Date: December 4, 2025

Welcome to the SmartNex.Tech Attendance System ("The Service"). By accessing or using the Service, you agree to be bound by these Terms of Use and all applicable laws and regulations.

1. Description of Service
The Service is a digital attendance and workforce management platform provided under contract specifically for use by Ray Engineering personnel and their authorized project managers.
...
(Full text same as original)
''';

const _privacyPolicyText = '''
SmartNex.Tech Construction Attendance System Privacy Policy
Effective Date: December 4, 2025

SmartNex.Tech is committed to protecting the privacy and security of your data.
...
(Full text same as original)
''';
// ─────────────────────────────────────────────────────────────────────────────

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LoginController());
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Login",
            style: TextStyle(
                color: controller.primaryBlue,
                fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 180,
                child: Lottie.asset("assets/lottie/admin_login.json",
                    fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              Text(
                "Accurate attendance. Anytime. Anywhere.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: controller.primaryBlue),
              ),
              const SizedBox(height: 30),

              // Email Field
              TextField(
                controller: controller.emailController,
                decoration: InputDecoration(
                  labelText: "Email or User ID",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              Obx(() => TextField(
                    controller: controller.passwordController,
                    obscureText: controller.obscurePassword.value,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: controller.primaryBlue),
                        onPressed: () =>
                            controller.obscurePassword.toggle(),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  )),
              const SizedBox(height: 16),

              // Terms Row
              Obx(() => Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: controller.acceptedTerms.value,
                        activeColor: controller.primaryBlue,
                        onChanged: (val) =>
                            controller.acceptedTerms.value = val ?? false,
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                color: Colors.grey[800], fontSize: 14),
                            children: [
                              const TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "Terms",
                                style: TextStyle(
                                    color: controller.primaryBlue,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _showUserAgreementDialog,
                              ),
                              const TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy",
                                style: TextStyle(
                                    color: controller.primaryBlue,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _showPrivacyPolicyDialog,
                              ),
                              const TextSpan(text: "."),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 16),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                      onPressed: controller.canLogin
                          ? controller.handleLogin
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: controller.primaryBlue,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: controller.isLoggingIn.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text("Login",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white)),
                    )),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: controller.showForgotPasswordDialog,
                child: Text("Forgot Password?",
                    style: TextStyle(color: controller.primaryBlue)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserAgreementDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("User Agreement"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(_userAgreementText,
                style: const TextStyle(fontSize: 13)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Privacy Policy"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(_privacyPolicyText,
                style: const TextStyle(fontSize: 13)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text("Close")),
        ],
      ),
    );
  }
}
