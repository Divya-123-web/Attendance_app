// dashboard_provider.dart
// State management for the Teacher Dashboard.
// Combines auth state + attendance data into one place.

import 'dart:async';
import 'package:attendanceapp/provider/student_provider.dart';
import 'package:flutter/material.dart';
import '../models/attendance_record_model.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();

  // State
  List<AttendanceRecord> _attendanceRecords = [];
  List<StudentModel> _allStudents = [];
  Map<String, int> _weeklyData = {};
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
  bool _isLoading = false;
  String _errorMessage = '';
  StreamSubscription? _attendanceSubscription;

  // Search/filter
  String _searchQuery = '';
  String _filterStatus = 'All'; // 'All', 'Present', 'Absent'

  // Getters
  List<AttendanceRecord> get attendanceRecords => _filteredRecords;
  List<StudentModel> get allStudents => _allStudents;
  Map<String, int> get weeklyData => _weeklyData;
  String get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;
  bool get isLoggedIn => _authService.isLoggedIn;

  // ─────────────────────────────────────────
  // FILTERED RECORDS (search + status filter)
  // ─────────────────────────────────────────
  List<AttendanceRecord> get _filteredRecords {
    var records = _attendanceRecords;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      records = records.where((r) =>
        r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        r.registerNumber.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply status filter
    if (_filterStatus == 'Present') {
      records = records.where((r) => r.isPresent).toList();
    } else if (_filterStatus == 'Absent') {
      records = records.where((r) => !r.isPresent).toList();
    }

    return records;
  }

  // ─────────────────────────────────────────
  // DASHBOARD SUMMARY (computed property)
  // Calculates stats from current records + all students
  // ─────────────────────────────────────────
  DashboardSummary get summary {
    final total = _allStudents.length;
    final present = _attendanceRecords.where((r) => r.isPresent).length;
    final absent = total - present;
    final percentage = total > 0 ? (present / total * 100) : 0.0;

    return DashboardSummary(
      totalStudents: total,
      presentCount: present,
      absentCount: absent < 0 ? 0 : absent,
      attendancePercentage: percentage.toDouble(),
    );
  }

  // ─────────────────────────────────────────
  // ABSENT STUDENTS LIST
  // Students in Firestore but not in today's logs
  // ─────────────────────────────────────────
  List<StudentModel> get absentStudents {
    final presentRegNos = _attendanceRecords
        .where((r) => r.isPresent)
        .map((r) => r.registerNumber)
        .toSet();

    return _allStudents
        .where((s) => !presentRegNos.contains(s.registerNumber))
        .toList();
  }

  // ─────────────────────────────────────────
  // TEACHER LOGIN
  // ─────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
      await initializeDashboard();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _attendanceSubscription?.cancel();
    await _authService.signOut();
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // INITIALIZE DASHBOARD DATA
  // Called once after login
  // ─────────────────────────────────────────
  Future<void> initializeDashboard() async {
    _setLoading(true);
    try {
      // Load all students and weekly chart data in parallel
      final results = await Future.wait([
        _dashboardService.getAllStudents(),
        _dashboardService.getWeeklyAttendance(),
      ]);

      _allStudents = results[0] as List<StudentModel>;
      _weeklyData = results[1] as Map<String, int>;

      // Start listening to real-time attendance stream
      _subscribeToAttendance(_selectedDate);

      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // REAL-TIME ATTENDANCE SUBSCRIPTION
  // Cancels old subscription, starts new one for the selected date
  // ─────────────────────────────────────────
  void _subscribeToAttendance(String date) {
    // Cancel previous stream before subscribing to new one
    _attendanceSubscription?.cancel();

    _attendanceSubscription = _dashboardService
        .getAttendanceByDateStream(date)
        .listen((records) {
      _attendanceRecords = records;
      notifyListeners(); // Rebuild UI with fresh data
    });
  }

  // ─────────────────────────────────────────
  // CHANGE SELECTED DATE
  // ─────────────────────────────────────────
  void selectDate(String date) {
    _selectedDate = date;
    _subscribeToAttendance(date);
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // MANUAL OVERRIDE
  // ─────────────────────────────────────────
  Future<void> overrideAttendance(String recordId, bool isPresent) async {
    try {
      await _dashboardService.overrideAttendance(recordId, isPresent);
      // Stream will auto-update UI — no manual setState needed
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> manuallyMarkPresent(StudentModel student) async {
    try {
      await _dashboardService.manuallyMarkPresent(student);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<List<AttendanceRecord>> getAttendanceInRange(
      String startDate, String endDate) async {
    return await _dashboardService.getAttendanceByRange(startDate, endDate);
  }

  Future<List<AttendanceRecord>> getStudentAttendanceHistory(
      String registerNumber) async {
    return await _dashboardService.getStudentHistory(registerNumber);
  }

  // Search and filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    super.dispose();
  }
}