import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'overtime_submission_controller.dart';

class OvertimeSubmissionView extends GetView<OvertimeSubmissionController> {
  const OvertimeSubmissionView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OvertimeSubmissionController());
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: controller.themeBlue,
        centerTitle: true,
        title: const Text("Overtime",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("Date"),
            Obx(() => _pickerField(
              controller.formattedDate,
              Icons.calendar_today_outlined,
                  () => controller.pickDate(context),
            )),
            const SizedBox(height: 20),
            _title("Overtime Hours"),
            const SizedBox(height: 8),
            TextField(
              controller: controller.overtimeHoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "Enter hours (e.g. 2.5)",
                suffixText: "hrs",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _title("Reason"),
            TextField(
              controller: controller.reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter reason...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.submitOvertime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.themeBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: controller.isSubmitting.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Overtime",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              )),
            ),
          ],
        ),
      ),
      // body: SingleChildScrollView(
      //   padding: const EdgeInsets.all(18),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       _title("Date"),
      //       Obx(() => _pickerField(
      //             controller.formattedDate,
      //             Icons.calendar_today_outlined,
      //             () => controller.pickDate(context),
      //           )),
      //       const SizedBox(height: 20),
      //       _title("From Time"),
      //       Obx(() => _pickerField(
      //             controller.fromTimeLabel(context),
      //             Icons.access_time,
      //             () => controller.pickFromTime(context),
      //           )),
      //       const SizedBox(height: 20),
      //       _title("To Time"),
      //       Obx(() => _pickerField(
      //             controller.toTimeLabel(context),
      //             Icons.access_time,
      //             () => controller.pickToTime(context),
      //           )),
      //       const SizedBox(height: 20),
      //       _title("Reason"),
      //       TextField(
      //         controller: controller.reasonController,
      //         maxLines: 3,
      //         decoration: InputDecoration(
      //           hintText: "Enter reason...",
      //           border: OutlineInputBorder(
      //               borderRadius: BorderRadius.circular(10)),
      //           filled: true,
      //           fillColor: Colors.white,
      //         ),
      //       ),
      //       const SizedBox(height: 30),
      //       SizedBox(
      //         width: double.infinity,
      //         height: 52,
      //         child: Obx(() => ElevatedButton(
      //               onPressed: controller.isSubmitting.value
      //                   ? null
      //                   : controller.submitOvertime,
      //               style: ElevatedButton.styleFrom(
      //                 backgroundColor: controller.themeBlue,
      //                 shape: RoundedRectangleBorder(
      //                     borderRadius: BorderRadius.circular(10)),
      //               ),
      //               child: controller.isSubmitting.value
      //                   ? const CircularProgressIndicator(color: Colors.white)
      //                   : const Text("Submit Overtime",
      //                       style: TextStyle(
      //                           fontSize: 16,
      //                           fontWeight: FontWeight.w600,
      //                           color: Colors.white)),
      //             )),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _title(String text) => Text(text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));

  Widget _pickerField(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
