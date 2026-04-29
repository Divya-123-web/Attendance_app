// firebase_service.dart
// Handles ALL Firebase operations:
// - Saving student info to Firestore
// - Uploading face images to Firebase Storage
// - Marking attendance in Firestore

import 'dart:io';
import 'package:attendanceapp/models/student_models.dart';
import 'package:attendanceapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Get references to Firestore collections
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection name in Firestore
  static const String _usersCollection = 'users';

  // ─────────────────────────────────────────
  // 1. SAVE STUDENT REGISTRATION DATA
  // Called after Screen 1 form submission
  // ─────────────────────────────────────────
  Future<String> saveStudent(StudentModel student) async {
    try {
      // Use registerNumber as the document ID (unique per student)
      await _firestore
    .collection(_usersCollection)
    .doc(student.registerNumber)
    .set({
  'name': student.name,
  'registerNumber': student.registerNumber,
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
          .collection(_usersCollection)
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
      .collection(_usersCollection)
        .doc(student.registerNumber)
        .update({
      'attendanceMarked': true,
      'attendanceTime': DateTime.now().toIso8601String(),
    });

    // Save full student info to attendance_logs for dashboard use
    await _firestore.collection('attendance_logs').add({
      'registerNumber': student.registerNumber,
      'studentName': student.name,        // ← Name for dashboard display// ← Email for detail screen
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
          .collection(_usersCollection)
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
          .collection(_usersCollection)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  // ─────────────────────────────────────────
  // 6. SAVE USER DATA TO USERS COLLECTION
  // Uploads passport photo to storage and saves user data
  // ─────────────────────────────────────────
  Future<String> saveUser(UserModel user, File? imageFile) async {
    try {
      String photoUrl = user.passportSizePhoto; // Default to existing URL

      // If image file provided, upload to storage
      if (imageFile != null && await imageFile.exists()) {
        try {
          // Validate image file is not empty
          final fileSize = await imageFile.length();
          if (fileSize == 0) {
            print('⚠️ Image file is empty, skipping upload');
          } else {
            final storageRef = _storage
                .ref()
                .child('passport_photos')
                .child('${user.registerNumber}.jpg');

            final uploadTask = await storageRef.putFile(imageFile);
            photoUrl = await uploadTask.ref.getDownloadURL();
            print('✅ Image uploaded: $photoUrl');
          }
        } catch (imageError) {
          print('⚠️ Image upload failed: $imageError');
          // Continue without image - don't fail entire user save
        }
      }

      // Update user with photo URL
      final userWithPhoto = user.copyWith(passportSizePhoto: photoUrl);

      // Save to users collection using register number as document ID
      await _firestore
          .collection('users')
          .doc(user.registerNumber.toString())
          .set(userWithPhoto.toMap());

      print('✅ User saved: ${user.name}');
      return user.registerNumber.toString();
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  // ─────────────────────────────────────────
  // 7. GET USER BY REGISTER NUMBER
  // Used to retrieve user data from users collection
  // ─────────────────────────────────────────
  Future<UserModel?> getUser(String registerNumber) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(registerNumber)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }
}