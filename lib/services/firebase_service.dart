// firebase_service.dart
// Handles ALL Firebase operations:
// - Saving student info to Firestore
// - Uploading face images to Firebase Storage
// - Marking attendance in Firestore

import 'dart:io';
import 'package:attendanceapp/models/student_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Get references to Firestore collections
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection name in Firestore
  static const String _studentsCollection = 'students';

  // ─────────────────────────────────────────
  // 1. SAVE STUDENT REGISTRATION DATA
  // Called after Screen 1 form submission
  // ─────────────────────────────────────────
  Future<String> saveStudent(StudentModel student) async {
    try {
      // Use registerNumber as the document ID (unique per student)
      await _firestore
    .collection('students')
    .doc(student.registerNumber)
    .set({
  'name': student.name,
  'registerNumber': student.registerNumber,
  'email': student.email,
  'attendanceMarked': false,
});
      print('✅ Student saved: ${student.name}');
      return student.registerNumber;
    } catch (e) {
      throw Exception('Failed to save student: $e');
    }
  }

  // ─────────────────────────────────────────
  // 2. UPLOAD FACE IMAGE TO FIREBASE STORAGE
  // Called after face capture in Screen 2
  // ─────────────────────────────────────────
  Future<String> uploadFaceImage(String registerNumber, File imageFile) async {
    try {
      // Create a storage path: faces/REG001.jpg
      final storageRef = _storage
          .ref()
          .child('faces')
          .child('$registerNumber.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get the public download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save the URL back to the student's Firestore document
      await _firestore
          .collection(_studentsCollection)
          .doc(registerNumber)
          .update({'faceImageUrl': downloadUrl});

      print('✅ Face image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload face image: $e');
    }
  }

  // ─────────────────────────────────────────
  // 3. MARK ATTENDANCE
  // Called after both face + location verified
  // ─────────────────────────────────────────
  // In firebase_service.dart — replace markAttendance() with this:

Future<void> markAttendance(StudentModel student) async {
  try {
    await _firestore
        .collection(_studentsCollection)
        .doc(student.registerNumber)
        .update({
      'attendanceMarked': true,
      'attendanceTime': DateTime.now().toIso8601String(),
    });

    // Save full student info to attendance_logs for dashboard use
    await _firestore.collection('attendance_logs').add({
      'registerNumber': student.registerNumber,
      'studentName': student.name,        // ← Name for dashboard display
      'studentEmail': student.email,      // ← Email for detail screen
      'timestamp': DateTime.now().toIso8601String(),
      'date': DateTime.now().toIso8601String().split('T')[0],
      'isPresent': true,
      'manualOverride': false,
    });

    print('✅ Attendance marked for: ${student.name}');
  } catch (e) {
    throw Exception('Failed to mark attendance: $e');
  }
}
  // ─────────────────────────────────────────
  // 4. GET STUDENT BY REGISTER NUMBER
  // Used to retrieve student data
  // ─────────────────────────────────────────
  Future<StudentModel?> getStudent(String registerNumber) async {
    try {
      final doc = await _firestore
          .collection(_studentsCollection)
          .doc(registerNumber)
          .get();

      if (doc.exists) {
        return StudentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student: $e');
    }
  }

  // ─────────────────────────────────────────
  // 5. GET ALL STUDENTS (for teacher report)
  // ─────────────────────────────────────────
  Future<List<StudentModel>> getAllStudents() async {
    try {
      final snapshot = await _firestore
          .collection(_studentsCollection)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }
}