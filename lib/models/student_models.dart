// student_model.dart
// This class represents a Student object.
// It handles conversion to/from Firestore JSON format.

class StudentModel {
  final String id;
  final String name;
  final String registerNumber;
  final String email;
  final String? faceImageUrl;  // URL of the stored face image in Firebase Storage
  final bool attendanceMarked;
  final DateTime? attendanceTime;

  StudentModel({
    required this.id,
    required this.name,
    required this.registerNumber,
    required this.email,
    this.faceImageUrl,
    this.attendanceMarked = false,
    this.attendanceTime,
  });

  // Convert Student object → Map (to save to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'registerNumber': registerNumber,
      'email': email,
      'faceImageUrl': faceImageUrl,
      'attendanceMarked': attendanceMarked,
      'attendanceTime': attendanceTime?.toIso8601String(),
    };
  }

  // Convert Firestore Map → Student object (to read from Firestore)
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      registerNumber: map['registerNumber'] ?? '',
      email: map['email'] ?? '',
      faceImageUrl: map['faceImageUrl'],
      attendanceMarked: map['attendanceMarked'] ?? false,
      attendanceTime: map['attendanceTime'] != null
          ? DateTime.parse(map['attendanceTime'])
          : null,
    );
  }

  // copyWith: Creates a modified copy without changing the original
  StudentModel copyWith({
    String? faceImageUrl,
    bool? attendanceMarked,
    DateTime? attendanceTime,
  }) {
    return StudentModel(
      id: id,
      name: name,
      registerNumber: registerNumber,
      email: email,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      attendanceMarked: attendanceMarked ?? this.attendanceMarked,
      attendanceTime: attendanceTime ?? this.attendanceTime,
    );
  }
}