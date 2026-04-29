// student_model.dart
// This class represents a Student object.
// It handles conversion to/from Firestore JSON format.

class StudentModel {
  final String id;
  final String name;
  final String email;
  final String emailId;
  final String emailAddress;
  final String registerNumber;
  final String department;
  final String year;
  final String sec;
  final String? faceImageUrl;  // URL of the stored face image in Firebase Storage
  final String passportSizePhoto;
  final bool attendanceMarked;
  final DateTime? attendanceTime;
  final bool isFaceRegistered;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.registerNumber,
    this.emailId = '',
    this.emailAddress = '',
    this.department = '',
    this.year = '',
    this.sec = '',
    this.faceImageUrl,
    this.passportSizePhoto = '',
    this.attendanceMarked = false,
    this.attendanceTime,
    this.isFaceRegistered = false,
  });

  // Convert Student object → Map (to save to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'emailId': emailId,
      'emailAddress': emailAddress,
      'registerNumber': registerNumber,
      'department': department,
      'year': year,
      'sec': sec,
      'faceImageUrl': faceImageUrl,
      'passportSizePhoto': passportSizePhoto,
      'attendanceMarked': attendanceMarked,
      'attendanceTime': attendanceTime?.toIso8601String(),
      'isFaceRegistered': isFaceRegistered,
    };
  }

  // Convert Firestore Map → Student object (to read from Firestore)
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? map['emailId'] ?? map['emailAddress'] ?? '',
      emailId: map['emailId'] ?? '',
      emailAddress: map['emailAddress'] ?? '',
      registerNumber: map['registerNumber'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      sec: map['sec'] ?? '',
      faceImageUrl: map['faceImageUrl'],
      passportSizePhoto: map['passportSizePhoto'] ?? '',
      attendanceMarked: map['attendanceMarked'] ?? false,
      attendanceTime: map['attendanceTime'] != null
          ? DateTime.parse(map['attendanceTime'])
          : null,
      isFaceRegistered: map['isFaceRegistered'] ?? false,
    );
  }

  // copyWith: Creates a modified copy without changing the original
  StudentModel copyWith({
    String? faceImageUrl,
    String? email,
    String? emailId,
    String? emailAddress,
    String? department,
    String? year,
    String? sec,
    String? passportSizePhoto,
    bool? attendanceMarked,
    DateTime? attendanceTime,
    bool? isFaceRegistered,
  }) {
    return StudentModel(
      id: id,
      name: name,
      email: email ?? this.email,
      registerNumber: registerNumber,
      emailId: emailId ?? this.emailId,
      emailAddress: emailAddress ?? this.emailAddress,
      department: department ?? this.department,
      year: year ?? this.year,
      sec: sec ?? this.sec,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      passportSizePhoto: passportSizePhoto ?? this.passportSizePhoto,
      attendanceMarked: attendanceMarked ?? this.attendanceMarked,
      attendanceTime: attendanceTime ?? this.attendanceTime,
      isFaceRegistered: isFaceRegistered ?? this.isFaceRegistered,
    );
  }
}