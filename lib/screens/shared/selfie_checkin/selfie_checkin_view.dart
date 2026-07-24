import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'selfie_checkin_controller.dart';

class SelfieCheckInView extends GetView<SelfieCheckInController> {
  const SelfieCheckInView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SelfieCheckInController());
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: controller.themeBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text("Selfie Check-In",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Obx(() => _buildInfoRow(
                        Icons.access_time, "Time", controller.dateTime.value)),
                    const Divider(height: 24),
                    _buildInfoRow(
                        Icons.person_outline, "Employee", controller.userName),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selfie Section
              Center(
                child: Column(
                  children: [
                    Obx(() {
                      final img = controller.selfieImage.value;
                      if (img != null) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      controller.themeBlue.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: ClipOval(
                            child: Image.file(img,
                                height: 180,
                                width: 180,
                                fit: BoxFit.cover),
                          ),
                        );
                      }
                      return Container(
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          border: Border.all(
                              color: controller.themeBlue, width: 3),
                        ),
                        child: Icon(Icons.camera_alt,
                            size: 60, color: Colors.grey[400]),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Location Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Obx(() => _buildInfoRow(Icons.gps_fixed, "Coordinates",
                        controller.coordsText.value)),
                    const Divider(height: 24),
                    Obx(() => _buildInfoRow(Icons.location_on_outlined,
                        "Location", controller.location.value)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(() {
                  final loading = controller.isLoading.value;
                  final hasImage = controller.selfieImage.value != null;

                  IconData icon =
                      hasImage ? Icons.check_circle : Icons.camera_alt;
                  String label =
                      hasImage ? "Confirm Check-In" : "Take Selfie";

                  return ElevatedButton(
                    onPressed: loading
                        ? null
                        : controller.onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.themeBlue,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: loading ? 0 : 4,
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16)),
                            ],
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: controller.themeBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: controller.themeBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
