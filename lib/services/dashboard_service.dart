// dashboard_service.dart
// Fetches and manages all attendance data from Firestore.
// Uses Streams for real-time updates — when Firestore changes,
// the UI automatically rebuilds without manual refresh.

import 'package:attendanceapp/provider/student_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record_model.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // REAL-TIME STREAM: Today's Attendance
  // Emits a new list every time Firestore updates
  // ─────────────────────────────────────────
  Stream<List<AttendanceRecord>> getTodayAttendanceStream() {
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    return _firestore
        .collection('attendance_logs')
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: true)
        // snapshots() returns a Stream — fires every time data changes
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // ─────────────────────────────────────────
  // REAL-TIME STREAM: Attendance by Date
  // ─────────────────────────────────────────
  Stream<List<AttendanceRecord>> getAttendanceByDateStream(String date) {
    return _firestore
        .collection('attendance_logs')
        .where('date', isEqualTo: date)
        // No orderBy here — sort in Dart below
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
              .toList();

          // Sort by timestamp in Dart (no index needed)
          records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return records;
        });
  }

  // ─────────────────────────────────────────
  // GET ALL STUDENTS (for absent calculation)
  // Returns all registered students
  // ─────────────────────────────────────────
  Future<List<StudentModel>> getAllStudents() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => StudentModel.fromMap(doc.data()))
        .toList();
  }

  // ─────────────────────────────────────────
  // GET STUDENT ATTENDANCE HISTORY
  // All attendance records for one student
  // ─────────────────────────────────────────
  Future<List<AttendanceRecord>> getStudentHistory(String registerNumber) async {
    final snapshot = await _firestore
        .collection('attendance_logs')
        .where('registerNumber', isEqualTo: registerNumber)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  // ─────────────────────────────────────────
  // ATTENDANCE RANGE QUERY
  // Returns all attendance records between two dates inclusive.
  // Date values are stored as YYYY-MM-DD strings in Firestore.
  // ─────────────────────────────────────────
  Future<List<AttendanceRecord>> getAttendanceByRange(
      String startDate, String endDate) async {
    final snapshot = await _firestore
        .collection('attendance_logs')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        return dateCompare != 0 ? dateCompare : a.timestamp.compareTo(b.timestamp);
      });
  }

  // ─────────────────────────────────────────
  // MANUAL OVERRIDE: Mark/Unmark Attendance
  // Teacher can override system-marked attendance
  // ─────────────────────────────────────────
  Future<void> overrideAttendance(String recordId, bool isPresent) async {
    await _firestore
        .collection('attendance_logs')
        .doc(recordId)
        .update({
      'isPresent': isPresent,
      'manualOverride': true,
      'overrideTime': DateTime.now().toIso8601String(),
    });
  }

  // ─────────────────────────────────────────
  // MANUAL ADD: Mark student present manually
  // For students who were physically present
  // but system verification failed
  // ─────────────────────────────────────────
  Future<void> manuallyMarkPresent(StudentModel student) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final now = DateTime.now();

    await _firestore.collection('attendance_logs').add({
      'registerNumber': student.registerNumber,
      'studentName': student.name,
      'studentEmail': student.email,
      'timestamp': now.toIso8601String(),
      'date': today,
      'isPresent': true,
      'manualOverride': true,
    });

    
  }

  // ─────────────────────────────────────────
  // GET WEEKLY ATTENDANCE DATA
  // For the bar chart in dashboard
  // Returns Map<"Mon", presentCount>
  // ─────────────────────────────────────────
  Future<Map<String, int>> getWeeklyAttendance() async {
    final now = DateTime.now();
    final Map<String, int> weekData = {};
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Go back 7 days and count attendance for each
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = day.toIso8601String().split('T')[0];
      final dayName = dayNames[day.weekday - 1];

      final snapshot = await _firestore
          .collection('attendance_logs')
          .where('date', isEqualTo: dateStr)
          .where('isPresent', isEqualTo: true)
          .get();

      weekData[dayName] = snapshot.docs.length;
    }

    return weekData;
  }
}