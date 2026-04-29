// hod_provider.dart
// State management for the HOD portal.

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/hod_service.dart';

enum HodLoadingState { idle, loading, success, error }

class HodProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final HodService _hodService = HodService();

  // State
  Map<String, dynamic> _deptStats = {};
  List<Map<String, dynamic>> _lowAttendanceStudents = [];
  Map<String, int> _monthlyData = {};
  List<Map<String, dynamic>> _teachers = [];
  HodLoadingState _state = HodLoadingState.idle;
  String _errorMessage = '';
  double _alertThreshold = 75.0;

  // Getters
  Map<String, dynamic> get deptStats => _deptStats;
  List<Map<String, dynamic>> get lowAttendanceStudents => _lowAttendanceStudents;
  Map<String, int> get monthlyData => _monthlyData;
  List<Map<String, dynamic>> get teachers => _teachers;
  bool get isLoading => _state == HodLoadingState.loading;
  String get errorMessage => _errorMessage;
  double get alertThreshold => _alertThreshold;
  bool get isLoggedIn => _authService.isLoggedIn;

  // ─────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _state = HodLoadingState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      await loadDashboard();
      return true;
    } catch (e) {
      _state = HodLoadingState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _deptStats = {};
    _lowAttendanceStudents = [];
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // LOAD ALL DASHBOARD DATA
  // ─────────────────────────────────────────
  Future<void> loadDashboard() async {
    _state = HodLoadingState.loading;
    notifyListeners();

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _hodService.getDepartmentStats(),
        _hodService.getLowAttendanceStudents(threshold: _alertThreshold),
        _hodService.getMonthlyAttendance(),
        _hodService.getAllTeachers(),
      ]);

      _deptStats = results[0] as Map<String, dynamic>;
      _lowAttendanceStudents = results[1] as List<Map<String, dynamic>>;
      _monthlyData = results[2] as Map<String, int>;
      _teachers = results[3] as List<Map<String, dynamic>>;

      _state = HodLoadingState.success;
      notifyListeners();
    } catch (e) {
      _state = HodLoadingState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Change the low-attendance alert threshold
  void setThreshold(double value) {
    _alertThreshold = value;
    notifyListeners();
    // Reload with new threshold
    _hodService
        .getLowAttendanceStudents(threshold: value)
        .then((data) {
      _lowAttendanceStudents = data;
      notifyListeners();
    });
  }
}