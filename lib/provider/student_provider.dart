// This model represents a Student object throughout the app.
// It maps to a Firestore document.

class StudentModel {
  final String id;
  final String name;
  final String registerNumber;
  final String email;
  final String emailId;
  final String emailAddress;
  final String department;
  final String year;
  final String sec;
  final String passportSizePhoto;
  final int phoneNumber;
  final String timestamp;
  final String? faceImageUrl; // URL of face image stored in Firebase Storage
  bool isFaceRegistered;
  bool attendanceMarked;
  DateTime? attendanceTime;

  StudentModel({
    required this.id,
    required this.name,
    required this.registerNumber,
    required this.email,
    this.emailId = '',
    this.emailAddress = '',
    this.department = '',
    this.year = '',
    this.sec = '',
    this.passportSizePhoto = '',
    this.phoneNumber = 0,
    this.timestamp = '',
    this.faceImageUrl,
    this.isFaceRegistered = false,
    this.attendanceMarked = false,
    this.attendanceTime,
  });

  // Convert StudentModel → Map (to save to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'registerNumber': registerNumber,
      'email': email,
      'emailId': emailId,
      'emailAddress': emailAddress,
      'department': department,
      'year': year,
      'sec': sec,
      'passportSizePhoto': passportSizePhoto,
      'phoneNumber': phoneNumber,
      'timestamp': timestamp,
      'faceImageUrl': faceImageUrl,
      'isFaceRegistered': isFaceRegistered,
      'attendanceMarked': attendanceMarked,
      'attendanceTime': attendanceTime?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Convert Firestore document → StudentModel
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? map['registerNumber']?.toString() ?? '',
      name: map['name'] ?? '',
      registerNumber: map['registerNumber']?.toString() ?? '',
      email: map['email'] ?? map['emailId'] ?? map['emailAddress'] ?? '',
      emailId: map['emailId'] ?? '',
      emailAddress: map['emailAddress'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      sec: map['sec'] ?? '',
      passportSizePhoto: map['passportSizePhoto'] ?? '',
      phoneNumber: map['phoneNumber'] is int
          ? map['phoneNumber'] as int
          : int.tryParse(map['phoneNumber']?.toString() ?? '') ?? 0,
      timestamp: map['timestamp'] ?? '',
      faceImageUrl: map['faceImageUrl'],
      isFaceRegistered: map['isFaceRegistered'] ?? false,
      attendanceMarked: map['attendanceMarked'] ?? false,
      attendanceTime: map['attendanceTime'] != null
          ? DateTime.tryParse(map['attendanceTime'])
          : null,
    );
  }

  // Create a copy with modified fields
  StudentModel copyWith({
    String? id,
    String? name,
    String? registerNumber,
    String? email,
    String? emailId,
    String? emailAddress,
    String? department,
    String? year,
    String? sec,
    String? passportSizePhoto,
    int? phoneNumber,
    String? timestamp,
    String? faceImageUrl,
    bool? isFaceRegistered,
    bool? attendanceMarked,
    DateTime? attendanceTime,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      registerNumber: registerNumber ?? this.registerNumber,
      email: email ?? this.email,
      emailId: emailId ?? this.emailId,
      emailAddress: emailAddress ?? this.emailAddress,
      department: department ?? this.department,
      year: year ?? this.year,
      sec: sec ?? this.sec,
      passportSizePhoto: passportSizePhoto ?? this.passportSizePhoto,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      timestamp: timestamp ?? this.timestamp,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      isFaceRegistered: isFaceRegistered ?? this.isFaceRegistered,
      attendanceMarked: attendanceMarked ?? this.attendanceMarked,
      attendanceTime: attendanceTime ?? this.attendanceTime,
    );
  }
}