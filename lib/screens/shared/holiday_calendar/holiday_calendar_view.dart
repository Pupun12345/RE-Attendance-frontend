import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'holiday_calendar_controller.dart';

class HolidayCalendarView extends GetView<HolidayCalendarController> {
  const HolidayCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HolidayCalendarController());
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: controller.themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text("Holiday Calendar",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!,
                  style: const TextStyle(color: Colors.red)));
        }
        if (controller.holidays.isEmpty) {
          return const Center(child: Text("No holidays found."));
        }
        return RefreshIndicator(
          onRefresh: controller.fetchHolidays,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.holidays.length,
            itemBuilder: (context, index) {
              final item = controller.holidays[index];
              final icon = controller.getIconForType(item.type);
              final color = controller.getColorForType(item.type);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(controller.formatDate(item.date),
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
