/* lib/screens/shared/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ --- FIXED IMPORTS ---
import 'package:smartcare_app/screens/shared/login_screen.dart';
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:smartcare_app/screens/management/management_dashboard_screen.dart';
// ✅ --- END OF FIX ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userString = prefs.getString('user'); // Get saved user object

      if (token != null && token.isNotEmpty && userString != null) {
        // User is logged in, find their role
        final Map<String, dynamic> user = jsonDecode(userString);
        final String role = user['role'];

        if (!mounted) return;
        Widget page;

        // Redirect based on role
        if (role == 'admin') {
          page = const AdminDashboardScreen();
        } else if (role == 'supervisor') {
          page = const SupervisorDashboardScreen();
        } else if (role == 'management') {
          page = const ManagementDashboardScreen(); 
        } else {
          page = const LoginScreen(); // Unknown role
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );

      } else {
        // Not logged in
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Error, go to login
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset(
            "assets/images/logo.png", // Make sure this path is correct
            height: 150,
          ),
        ),
      ),
    );
  }
}
*/

// lib/screens/shared/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare_app/screens/shared/login_screen.dart';
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:smartcare_app/screens/management/management_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userString = prefs.getString('user');

      if (token != null && token.isNotEmpty && userString != null) {
        final Map<String, dynamic> user = jsonDecode(userString);
        final String role = user['role'];

        if (!mounted) return;
        Widget page;

        if (role == 'admin') {
          page = const AdminDashboardScreen();
        } else if (role == 'supervisor') {
          page = const SupervisorDashboardScreen();
        } else if (role == 'management') {
          page = const ManagementDashboardScreen();
        } else {
          page = const LoginScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

     
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // 🔹 TOP (Empty for spacing)
            const SizedBox(height: 20),

            // 🔹 CENTER — Splash Animation Logo
            Expanded(
              child: Center(
                child: ScaleTransition(
                  scale: _animation,
                  child: Image.asset(
                    "assets/images/logo.png",
                    height: 150,
                  ),
                ),
              ),
            ),

            // 🔹 FOOTER SECTION (Added)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: 22, // very small logo
                    child: Image.asset(
                      "assets/images/smartnexlogo.jpg",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 6),

                  const Text(
                    "Made by SMARTNEX Technologies Pvt. Ltd.\nAll rights reserved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}