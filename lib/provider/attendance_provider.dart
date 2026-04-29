import 'dart:io';
import 'package:flutter/material.dart';
import '../provider/student_provider.dart';
import '../services/location_service.dart' as loc;
import '../services/dashboard_service.dart';

enum LoadingState { idle, loading, success, error }

class AttendanceProvider extends ChangeNotifier {
  final loc.LocationService _locationService = loc.LocationService();
  final DashboardService _dashboardService = DashboardService();

  loc.LocationResult? _locationResult;
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';
  StudentModel? _currentStudent;

  loc.LocationResult? get locationResult => _locationResult;
  String get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == LoadingState.loading;
  StudentModel? get student => _currentStudent;

  /// ✅ MAIN LOCATION FUNCTION (THIS WAS MISSING)
  Future<bool> verifyLocation() async {
    _setLoading();

    try  {
      final hasPermission = await _locationService.requestPermission();

      if (hasPermission == false) {
        _setError('Location permission denied');
        return false;
      }

      final serviceEnabled =
          await _locationService.isLocationServiceEnabled();

      if (serviceEnabled != true) {
        _setError('Turn ON GPS');
        return false;
      }

      final result = await _locationService.verifyLocation();

      _locationResult = result;

      if (!_locationResult!.isInsideGeofence) {
        _setError(
          'You are ${_locationResult!.distanceFromClassroom.toStringAsFixed(0)}m away',
        );
        return false;
      }

      _setSuccess();
      return true;
    } catch (e) {
      _setError('Error: $e');
      return false;
    }
  }

  /// FACE (dummy)
  Future<bool> verifyFace(File file) async {
    _setLoading();
    await Future.delayed(const Duration(seconds: 1));
    _setSuccess();
    return true;
  }

  /// MARK ATTENDANCE — Write to Firebase after location verification
  Future<bool> markAttendance() async {
    _setLoading();

    try {
      if (_currentStudent == null) {
        _setError('No student');
        return false;
      }

      // ✅ Write attendance log to Firebase
      await _dashboardService.manuallyMarkPresent(_currentStudent!);

      _currentStudent = _currentStudent!.copyWith(
        attendanceMarked: true,
        attendanceTime: DateTime.now(),
      );

      _setSuccess();
      return true;
    } catch (e) {
      _setError('Attendance failed: $e');
      return false;
    }
  }

  /// REGISTER
  Future<bool> registerStudent({
    required String name,
    required String registerNumber,
  }) async {
    _setLoading();

    try {
      _currentStudent = StudentModel(
        id: registerNumber,
        name: name,
        registerNumber: registerNumber,
        email: '',
        faceImageUrl: null,
        attendanceMarked: false,
      );

      _setSuccess();
      return true;
    } catch (e) {
      _setError('Registration failed');
      return false;
    }
  }

  /// HELPERS
  void _setLoading() {
    _loadingState = LoadingState.loading;
    _errorMessage = '';
    notifyListeners();
  }

  void _setSuccess() {
    _loadingState = LoadingState.idle;
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = LoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void reset() {
    _currentStudent = null;
    _locationResult = null;
    _errorMessage = '';
    _loadingState = LoadingState.idle;
    notifyListeners();
  }
}