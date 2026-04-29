// hod_service.dart
// Handles all HOD-specific Firebase operations:
// - Department-wide attendance stats
// - Low attendance student alerts
// - Teacher management

import 'package:attendanceapp/models/hod_models.dart';
import 'package:attendanceapp/provider/student_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // GET ALL STUDENTS WITH LOW ATTENDANCE
  // Returns students below threshold (default 75%)
  // ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLowAttendanceStudents({
    double threshold = 75.0,
  }) async {
    try {
      // Get all students
      final studentsSnap = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> lowAttendance = [];

      for (final doc in studentsSnap.docs) {
        final student = StudentModel.fromMap(doc.data());

        // Get all attendance logs for this student
        final logsSnap = await _firestore
            .collection('attendance_logs')
            .where('registerNumber', isEqualTo: student.registerNumber)
            .get();

        if (logsSnap.docs.isEmpty) {
          // No records = 0% attendance — definitely low
          lowAttendance.add({
            'student': student,
            'totalClasses': 0,
            'attended': 0,
            'percentage': 0.0,
          });
          continue;
        }

        final total = logsSnap.docs.length;
        final attended = logsSnap.docs
            .where((d) => d.data()['isPresent'] == true)
            .length;
        final percentage = (attended / total) * 100;

        if (percentage < threshold) {
          lowAttendance.add({
            'student': student,
            'totalClasses': total,
            'attended': attended,
            'percentage': percentage,
          });
        }
      }

      // Sort by percentage ascending (worst first)
      lowAttendance.sort((a, b) =>
          (a['percentage'] as double).compareTo(b['percentage'] as double));

      return lowAttendance;
    } catch (e) {
      throw Exception('Failed to get low attendance data: $e');
    }
  }

  // ─────────────────────────────────────────
  // GET DEPARTMENT-WIDE STATS
  // Overall numbers across all students
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> getDepartmentStats() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Run both queries in parallel for speed
      final results = await Future.wait([
        _firestore.collection('users').get(),
        _firestore
            .collection('attendance_logs')
            .where('date', isEqualTo: today)
            .where('isPresent', isEqualTo: true)
            .get(),
        _firestore.collection('attendance_logs').get(),
      ]);

      final totalStudents = results[0].docs.length;
      final presentToday = results[1].docs.length;
      final allLogs = results[2].docs;

      // Calculate overall attendance rate across all time
      final totalLogs = allLogs.length;
      final totalPresent =
          allLogs.where((d) => d.data()['isPresent'] == true).length;
      final overallRate =
          totalLogs > 0 ? (totalPresent / totalLogs * 100) : 0.0;

      return {
        'totalStudents': totalStudents,
        'presentToday': presentToday,
        'absentToday': totalStudents - presentToday,
        'todayRate': totalStudents > 0
            ? (presentToday / totalStudents * 100)
            : 0.0,
        'overallRate': overallRate,
        'totalLogsAllTime': totalLogs,
      };
    } catch (e) {
      throw Exception('Failed to get department stats: $e');
    }
  }

  // ─────────────────────────────────────────
  // GET MONTHLY ATTENDANCE DATA
  // Returns attendance count per day for current month
  // Used for the HOD monthly calendar chart
  // ─────────────────────────────────────────
  Future<Map<String, int>> getMonthlyAttendance() async {
    try {
      final now = DateTime.now();
      final Map<String, int> monthData = {};

      // Get first day of current month
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      for (int day = 1; day <= daysInMonth && day <= now.day; day++) {
        final date = DateTime(now.year, now.month, day);
        final dateStr = date.toIso8601String().split('T')[0];

        final snap = await _firestore
            .collection('attendance_logs')
            .where('date', isEqualTo: dateStr)
            .where('isPresent', isEqualTo: true)
            .get();

        monthData[day.toString()] = snap.docs.length;
      }

      return monthData;
    } catch (e) {
      throw Exception('Failed to get monthly data: $e');
    }
  }

  // ─────────────────────────────────────────
  // GET ALL TEACHERS
  // Lists all teacher accounts from Firestore
  // ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      return snap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get teachers: $e');
    }
  }

  // ─────────────────────────────────────────
  // SAVE HOD PROFILE TO FIRESTORE
  // Called when HOD account is created
  // ─────────────────────────────────────────
  Future<void> saveHodProfile(HodModel hod) async {
    await _firestore
        .collection('users')
        .doc(hod.id)
        .set(hod.toMap());
  }

  // ─────────────────────────────────────────
  // GET ALL STUDENTS (for HOD view)
  // ─────────────────────────────────────────
  Stream<List<StudentModel>> getAllStudentsStream() {
    return _firestore
      .collection('users')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }
}