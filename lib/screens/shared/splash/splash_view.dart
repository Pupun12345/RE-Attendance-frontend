import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.9, end: 1.4),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Image.asset("assets/images/logo.png", height: 150),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: 22,
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
