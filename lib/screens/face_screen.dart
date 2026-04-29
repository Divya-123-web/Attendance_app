// face_screen.dart
// SCREEN 2: Captures student's face using the camera.
// Uses Google ML Kit to detect the face in the image.
// Uploads the face image to Firebase Storage.

import 'dart:io';
import 'package:attendanceapp/provider/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'location_screen.dart';

class FaceScreen extends StatefulWidget {
  const FaceScreen({super.key});

  @override
  State<FaceScreen> createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _capturedImage;
  bool _isCameraReady = false;
  bool _imageCaptured = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // Initialize front camera for face capture
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      // Find front camera (index 1 is usually front)
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // ResolutionPreset.high = good quality for face detection
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false, // No audio needed
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      print('Camera init error: $e');
    }
  }

  // Capture photo from camera
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // takePicture() saves to a temp file and returns XFile
      final XFile photo = await _cameraController!.takePicture();

      setState(() {
        _capturedImage = File(photo.path);
        _imageCaptured = true;
      });
    } catch (e) {
      print('Capture error: $e');
    }
  }

  // Retake the photo
  void _retake() {
    setState(() {
      _capturedImage = null;
      _imageCaptured = false;
    });
    context.read<AttendanceProvider>().clearError();
  }

  // Submit captured face for verification
  Future<void> _verifyFace() async {
    if (_capturedImage == null) return;

    final provider = context.read<AttendanceProvider>();
    await provider.verifyFace(_capturedImage!);

    // if (success && mounted) {
    if(mounted){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LocationScreen()),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Face Recognition',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress indicator
                  _buildProgressBar(2),
                  const SizedBox(height: 16),

                  const Text(
                    'Step 2 of 3 — Face Registration',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Instructions card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Color(0xFF6C63FF)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Look straight at the camera. Keep your face centered and eyes open.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Camera / Image preview area
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _imageCaptured && _capturedImage != null
                          ? Image.file(
                              _capturedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : _isCameraReady
                              ? CameraPreview(_cameraController!)
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Face oval guide overlay
                  if (!_imageCaptured)
                    const Text(
                      '⬆ Position your face inside the frame',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),

                  // Error message
                  if (provider.errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action buttons
                  if (!_imageCaptured)
                    _buildCaptureButton()
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _retake,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retake'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: provider.isLoading ? null : _verifyFace,
                            icon: provider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.face_retouching_natural),
                            label: Text(
                              provider.isLoading ? 'Verifying...' : 'Verify Face',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 4),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6C63FF),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final isActive = step <= currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF6C63FF) : Colors.white12,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}