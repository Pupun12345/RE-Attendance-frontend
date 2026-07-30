import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

/// Full-screen selfie capture locked to the front-facing camera.
/// No camera-switch control is shown, so users cannot fall back to the
/// rear camera for attendance selfies.
class FrontCameraCaptureView extends StatefulWidget {
  const FrontCameraCaptureView({super.key});

  @override
  State<FrontCameraCaptureView> createState() =>
      _FrontCameraCaptureViewState();
}

class _FrontCameraCaptureViewState extends State<FrontCameraCaptureView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFuture = _initCamera();
  }

  // The OS can reclaim the camera hardware the instant the app is
  // backgrounded (another app opening it, a screen lock, a phone call).
  // Without releasing our controller here first, the plugin throws on
  // whatever call touches it next - the classic random crash on check-in.
  // On resume we throw the old (now-invalid) controller away and open a
  // fresh one rather than trying to reuse it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller = null;
      controller.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _initFuture = _initCamera();
      if (mounted) setState(() {});
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        frontCamera,
        // Selfies don't need to be captured at full sensor resolution -
        // medium keeps the upload small without a visible quality loss on
        // a face-sized frame, and _compress() below shrinks it further.
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        // Widget went away while we were awaiting - release the camera
        // instead of leaking it (it would otherwise stay locked and the
        // next screen to request it would crash).
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = "Unable to access front camera: $e");
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final raw = await controller.takePicture();
      final compressed = await _compress(File(raw.path));
      if (mounted) Get.back(result: compressed);
    } catch (e) {
      if (mounted) {
        setState(() => _capturing = false);
        Get.snackbar("Error", "Failed to capture photo",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    }
  }

  Future<File> _compress(File original) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      original.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 720,
      minHeight: 720,
    );

    // If compression fails for any reason, upload the original rather than
    // blocking check-in entirely over a non-essential optimization.
    if (result == null) return original;
    return File(result.path);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initFuture,
          builder: (context, snapshot) {
            if (_error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Go Back",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final controller = _controller;
            if (controller == null ||
                snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Get.back(),
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _capturing ? null : _capture,
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: _capturing
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
