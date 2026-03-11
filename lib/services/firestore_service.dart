// This service handles ALL Firestore database operations.
// Keeps database logic separate from UI.

import 'package:attendanceapp/models/student_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Get a reference to the Firestore database
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  final String _studentsCollection = 'students';
  final String _attendanceCollection = 'attendance';

  // ─── STUDENT OPERATIONS ───────────────────────────────────────

  // Save new student to Firestore
  Future<void> saveStudent(StudentModel student) async {
    await _db
        .collection(_studentsCollection)
        .doc(student.id) // Use student ID as document ID
        .set(student.toMap());
  }

  // Check if register number already exists (prevent duplicates)
  Future<bool> isRegisterNumberExists(String registerNumber) async {
    final query = await _db
        .collection(_studentsCollection)
        .where('registerNumber', isEqualTo: registerNumber)
        .get();
    return query.docs.isNotEmpty;
  }

  // Get student by register number (for verification)
  Future<StudentModel?> getStudentByRegisterNumber(String registerNumber) async {
    final query = await _db
        .collection(_studentsCollection)
        .where('registerNumber', isEqualTo: registerNumber)
        .get();
    if (query.docs.isEmpty) return null;
    return StudentModel.fromMap(query.docs.first.data());
  }

  // Update face registration status
  Future<void> updateFaceRegistration(String studentId, String imageUrl) async {
    await _db.collection(_studentsCollection).doc(studentId).update({
      'faceImageUrl': imageUrl,
      'isFaceRegistered': true,
    });
  }

  // ─── ATTENDANCE OPERATIONS ────────────────────────────────────

  // Mark attendance in Firestore
  Future<String> markAttendance({
    required String studentId,
    required String studentName,
    required String registerNumber,
    required String email,
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.now();
    final attendanceId = '${registerNumber}_${now.millisecondsSinceEpoch}';

    await _db.collection(_attendanceCollection).doc(attendanceId).set({
      'attendanceId': attendanceId,
      'studentId': studentId,
      'studentName': studentName,
      'registerNumber': registerNumber,
      'email': email,
      'date': now.toIso8601String(),
      'dateFormatted': '${now.day}/${now.month}/${now.year}',
      'time': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      'latitude': latitude,
      'longitude': longitude,
      'faceVerified': true,
      'locationVerified': true,
      'status': 'Present',
    });

    return attendanceId;
  }

  // Check if student already marked attendance today
  Future<bool> isAttendanceMarkedToday(String registerNumber) async {
    final now = DateTime.now();
    final todayStr = '${now.day}/${now.month}/${now.year}';

    final query = await _db
        .collection(_attendanceCollection)
        .where('registerNumber', isEqualTo: registerNumber)
        .where('dateFormatted', isEqualTo: todayStr)
        .get();

    return query.docs.isNotEmpty;
  }

  // Get all attendance records (for teacher dashboard)
  Stream<QuerySnapshot> getAttendanceStream() {
    return _db
        .collection(_attendanceCollection)
        .orderBy('date', descending: true)
        .snapshots();
  }
}