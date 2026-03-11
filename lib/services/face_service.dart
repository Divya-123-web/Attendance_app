// face_service.dart
// Handles face detection using Google ML Kit.
// ML Kit runs ON-DEVICE — no internet needed for detection.
//
// How face recognition works here:
// REGISTRATION: Capture face → save image to Firebase Storage
// VERIFICATION: Capture face → confirm a face is detected → mark as verified
// (For production-level 1:1 matching, you'd use a dedicated face recognition
//  model or service like AWS Rekognition. ML Kit confirms PRESENCE of a face.)

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  // Configure the face detector
  // enableClassification: detects smiling, eyes open/closed
  // enableTracking: assigns tracking IDs to faces
  late final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.15, // Face must be at least 15% of image size
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // ─────────────────────────────────────────
  // DETECT FACES IN AN IMAGE FILE
  // Returns list of detected faces
  // ─────────────────────────────────────────
  Future<List<Face>> detectFaces(File imageFile) async {
    try {
      // InputImage is what ML Kit accepts
      final inputImage = InputImage.fromFile(imageFile);

      // processImage() runs the ML model on the image
      final faces = await _faceDetector.processImage(inputImage);

      print('🔍 Faces detected: ${faces.length}');
      return faces;
    } catch (e) {
      throw Exception('Face detection failed: $e');
    }
  }

  // ─────────────────────────────────────────
  // DETECT FACES FROM CAMERA IMAGE
  // Used for live camera feed verification
  // ─────────────────────────────────────────
  Future<List<Face>> detectFacesFromCamera(CameraImage cameraImage, InputImageRotation rotation) async {
    try {
      // Convert CameraImage format to InputImage format for ML Kit
      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(cameraImage.planes),
        metadata: InputImageMetadata(
          size: Size(
            cameraImage.width.toDouble(),
            cameraImage.height.toDouble(),
          ),
          rotation: rotation,
          format: InputImageFormat.nv21, // Android camera format
          bytesPerRow: cameraImage.planes[0].bytesPerRow,
        ),
      );

      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      throw Exception('Camera face detection failed: $e');
    }
  }

  // Helper: Merge all camera image planes into one byte array
  // Camera images come in YUV format with separate Y, U, V planes
  Uint8List _concatenatePlanes(List<Plane> planes) {
  final WriteBuffer allBytes = WriteBuffer();

  for (final Plane plane in planes) {
    allBytes.putUint8List(plane.bytes);
  }

  return allBytes.done().buffer.asUint8List();
}
  // ─────────────────────────────────────────
  // VALIDATE FACE QUALITY
  // Ensures face is front-facing and clear
  // ─────────────────────────────────────────
  bool isFaceValid(Face face) {
    // headEulerAngleY: left/right rotation (-ve = left, +ve = right)
    // headEulerAngleX: up/down tilt
    // We want the face looking straight at camera (within ±20 degrees)
    final yAngle = face.headEulerAngleY ?? 0;
    final xAngle = face.headEulerAngleX ?? 0;

    final bool isFacingCamera = yAngle.abs() < 20 && xAngle.abs() < 20;

    // Both eyes should be open (probability > 0.5)
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
    final bool eyesOpen = leftEyeOpen > 0.5 && rightEyeOpen > 0.5;

    return isFacingCamera && eyesOpen;
  }

  // Always dispose the detector to free memory
  void dispose() {
    _faceDetector.close();
  }
}