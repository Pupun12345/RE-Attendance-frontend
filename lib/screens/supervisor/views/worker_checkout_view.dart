// lib/screens/supervisor/views/worker_checkout_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartcare_app/screens/supervisor/controllers/worker_checkout_controller.dart';

class WorkerCheckOutView extends StatelessWidget {
  final String workerName;
  final String workerId;
  final String workerDbId;

  const WorkerCheckOutView({
    super.key,
    required this.workerName,
    required this.workerId,
    required this.workerDbId,
  });

  static const _blue      = Color(0xFF0B3B8C);
  static const _lightBlue = Color(0xFFE8F0FE);
  static const _green     = Color(0xFF1B8A4A);
  static const _orange    = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(WorkerCheckOutController());
    c.init(name: workerName, userId: workerId, dbId: workerDbId);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text('Punch Out',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          final hasImage  = c.lastCapturedImage.value != null;
          final isLoading = c.isCheckingOut.value;
          final isSuccess = c.checkOutSuccess.value;
          final isPending = c.isPending.value;
          final secs      = c.pendingSecondsLeft.value;

          return Stack(
            children: [
              // ── Main Content ──
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Time Card ──
                    _InfoCard(
                      icon: Icons.access_time_rounded,
                      color: _blue,
                      child: Text(c.timeString.value,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                    ),
                    const SizedBox(height: 12),

                    // ── Worker Card ──
                    _InfoCard(
                      icon: Icons.badge_outlined,
                      color: _blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(workerName,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 2),
                          Text(workerId,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Photo Section ──
                    Center(
                      child: GestureDetector(
                        onTap: (isLoading || isSuccess || isPending)
                            ? null
                            : c.openCamera,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasImage ? Colors.transparent : _lightBlue,
                            border: Border.all(
                              color: isSuccess
                                  ? _green
                                  : (hasImage ? _blue : Colors.grey.shade300),
                              width: isSuccess ? 4 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isSuccess ? _green : _blue)
                                    .withOpacity(0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: hasImage
                                ? Image.file(c.lastCapturedImage.value!,
                                fit: BoxFit.cover)
                                : Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 42,
                                    color: _blue.withOpacity(0.6)),
                                const SizedBox(height: 6),
                                Text('Tap to capture',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: _blue.withOpacity(0.6))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Retake option ──
                    if (hasImage &&
                        !isLoading &&
                        !isSuccess &&
                        !isPending) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: c.openCamera,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retake Photo',
                              style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600),
                        ),
                      ),
                    ],

                    // ── Success Banner ──
                    if (isSuccess) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _green.withOpacity(0.4), width: 1),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              color: _green, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$workerName checked out successfully!',
                              style: const TextStyle(
                                  color: _green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                          ),
                        ]),
                      ),
                    ],

                    // ── Pending Banner ──
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showPendingDetails(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _orange.withOpacity(0.4), width: 1),
                          ),
                          child: Row(children: [
                            const Icon(Icons.wifi_off_rounded,
                                color: _orange, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                secs > 0
                                    ? 'No internet. Retrying in ${secs}s... (tap for details)'
                                    : 'Waiting for network to sync. (tap for details)',
                                style: const TextStyle(
                                    color: _orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: _orange, size: 20),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Full-screen loader overlay ──
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(_blue),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Submitting Check-Out...',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 6),
                          Text('Please wait',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),

      // ── Bottom Action Bar ──
      bottomNavigationBar: SafeArea(
        child: Obx(() {
          final hasImage  = c.lastCapturedImage.value != null;
          final isLoading = c.isCheckingOut.value;
          final isSuccess = c.checkOutSuccess.value;
          final isPending = c.isPending.value;
          final secs      = c.pendingSecondsLeft.value;

          final bool isDisabled = isLoading || isSuccess || isPending;

          Color btnColor;
          IconData btnIcon;
          String btnLabel;

          if (isSuccess) {
            btnColor = _green;
            btnIcon  = Icons.check_circle_rounded;
            btnLabel = 'Checked Out ✓';
          } else if (isLoading) {
            btnColor = _blue.withOpacity(0.6);
            btnIcon  = Icons.hourglass_top_rounded;
            btnLabel = 'Submitting...';
          } else if (isPending) {
            btnColor = _orange;
            btnIcon  = Icons.hourglass_bottom_rounded;
            btnLabel = secs > 0
                ? 'Pending (${secs}s)'
                : 'Pending – Waiting for network';
          } else if (hasImage) {
            btnColor = _blue;
            btnIcon  = Icons.logout_rounded;
            btnLabel = 'Confirm Check Out';
          } else {
            btnColor = _blue;
            btnIcon  = Icons.camera_alt_rounded;
            btnLabel = 'Open Camera';
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.location_on_rounded,
                      size: 18, color: _blue.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(c.addressText.value,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF444444))),
                  ),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.gps_fixed_rounded,
                      size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(c.locationText.value,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ),
                ]),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton(
                      onPressed: isDisabled
                          ? null
                          : (hasImage ? c.confirmCheckOut : c.openCamera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        disabledBackgroundColor: btnColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: isDisabled ? 0 : 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ] else ...[
                            Icon(btnIcon, size: 22, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(btnLabel,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Pending Details Dialog ─────────────────────────────────
  void _showPendingDetails(WorkerCheckOutController c) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.wifi_off_rounded,
                      color: _orange, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Pending Check-Out',
                    style: TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ]),
              const SizedBox(height: 16),
              if (c.pendingImage.value != null)
                CircleAvatar(
                  radius: 55,
                  backgroundImage: FileImage(c.pendingImage.value!),
                ),
              const SizedBox(height: 14),
              _dialogRow(Icons.badge_outlined,
                  '$workerName ($workerId)'),
              const SizedBox(height: 8),
              _dialogRow(Icons.access_time_rounded,
                  c.pendingTime.value ?? c.timeString.value),
              const SizedBox(height: 8),
              _dialogRow(Icons.location_on_outlined,
                  c.pendingAddress.value ?? c.addressText.value),
              const SizedBox(height: 6),
              _dialogRow(Icons.gps_fixed_rounded,
                  c.pendingLocation.value ?? c.locationText.value),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close',
                      style: TextStyle(color: _blue)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _dialogRow(IconData icon, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: Colors.grey.shade600),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF333333)))),
    ]);
  }
}

// ── Reusable Info Card ─────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Widget child;
  const _InfoCard(
      {required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ]),
    );
  }
}