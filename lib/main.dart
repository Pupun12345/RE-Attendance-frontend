// lib/main.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/screens/shared/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCare Attendance',
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1), // Admin theme color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
        ),
      ),
      home: const SplashScreen(), // Start with the SplashScreen
    );
  }
}