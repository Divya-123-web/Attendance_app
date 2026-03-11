// attendance_provider.dart
// Central state manager using Provider pattern.
// Holds the student data and verification status throughout the app.
// All screens READ from and WRITE to this provider.

import 'dart:io';
import 'package:attendanceapp/models/student_models.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/face_service.dart';
import '../services/location_service.dart';
import '../services/email_service.dart';

// Enum to track the current step's loading state
enum LoadingState { idle, loading, success, error }

class AttendanceProvider extends ChangeNotifier {
  // Services
  final FirebaseService _firebaseService = FirebaseService();
  final FaceService _faceService = FaceService();
  final LocationService _locationService = LocationService();
  final EmailService _emailService = EmailService();

  // State variables
  StudentModel? _student;           // Current student data
  bool _faceVerified = false;       // Face verification result
  LocationResult? _locationResult;  // Location check result
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  // Getters (read-only access to state)
  StudentModel? get student => _student;
  bool get faceVerified => _faceVerified;
  LocationResult? get locationResult => _locationResult;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == LoadingState.loading;

  // ─────────────────────────────────────────
  // STEP 1: REGISTER STUDENT
  // Saves student info to Firestore
  // ─────────────────────────────────────────
  Future<bool> registerStudent({
    required String name,
    required String registerNumber,
    required String email,
  }) async {
    _setLoading();

    try {
      _student = StudentModel(
        id: registerNumber,
        name: name,
        registerNumber: registerNumber,
        email: email,
      );

      await _firebaseService.saveStudent(_student!);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────
  // STEP 2: VERIFY FACE
  // Detects face in captured image and uploads it
  // ─────────────────────────────────────────
  Future<bool> verifyFace(File imageFile) async {
    if (_student == null) {
      _setError('No student registered');
      return false;
    }

    _setLoading();

    try {
      // Run face detection on the captured image
      final faces = await _faceService.detectFaces(imageFile);

      if (faces.isEmpty) {
        _setError('No face detected. Please ensure your face is clearly visible.');
        return false;
      }

      // Validate the detected face quality
      final isValid = _faceService.isFaceValid(faces.first);
      if (!isValid) {
        _setError('Please look straight at the camera with eyes open.');
        return false;
      }

      // Upload the face image to Firebase Storage
      final imageUrl = await _firebaseService.uploadFaceImage(
        _student!.registerNumber,
        imageFile,
      );

      // Update student model with face image URL
      _student = _student!.copyWith(faceImageUrl: imageUrl);
      _faceVerified = true;

      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────
  // STEP 3: VERIFY LOCATION
  // Checks GPS position against classroom geofence
  // ─────────────────────────────────────────
  Future<bool> verifyLocation() async {
    _setLoading();

    try {
      // Request GPS permission first
      final hasPermission = await _locationService.requestPermission();
      if (!hasPermission) {
        _setError('Location permission denied. Please enable location access.');
        return false;
      }

      // Get location and check against geofence
      _locationResult = await _locationService.verifyLocation();

      if (!_locationResult!.isInsideGeofence) {
        _setError(
          'You are ${_locationResult!.distanceFromClassroom.toStringAsFixed(0)}m away from the classroom. '
          'Please move inside the classroom boundary.',
        );
        return false;
      }

      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────
  // STEP 4: MARK ATTENDANCE + SEND EMAIL
  // Final step after all verifications pass
  // ─────────────────────────────────────────
  Future<bool> markAttendance() async {
    if (_student == null || !_faceVerified || _locationResult == null) {
      _setError('Verification incomplete');
      return false;
    }

    _setLoading();

    try {
      // Mark attendance in Firestore
      await _firebaseService.markAttendance(_student!);

      // Update local student object with attendance info
      _student = _student!.copyWith(
        attendanceMarked: true,
        attendanceTime: DateTime.now(),
      );

      // Send email report to teacher
      await _emailService.sendAttendanceReport(_student!);

      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────
  // STATE HELPERS
  // ─────────────────────────────────────────
  void _setLoading() {
    _loadingState = LoadingState.loading;
    _errorMessage = '';
    notifyListeners(); // Tells all widgets listening to this provider to rebuild
  }

  void _setSuccess() {
    _loadingState = LoadingState.idle;
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = LoadingState.error;
    _errorMessage = message.replaceAll('Exception: ', '');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _loadingState = LoadingState.idle;
    notifyListeners();
  }

  // Reset everything (for a new student session)
  void reset() {
    _student = null;
    _faceVerified = false;
    _locationResult = null;
    _loadingState = LoadingState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}