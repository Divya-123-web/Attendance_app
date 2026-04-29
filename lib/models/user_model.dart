// user_model.dart
// Model for user data entry from json_data.dart

class UserModel {
  final String timestamp;
  final String name;
  final int registerNumber;
  final String emailId;
  final String department;
  final String year;
  final String sec;
  final int phoneNumber;
  String passportSizePhoto; // Will be replaced with Firebase Storage URL
  final String emailAddress;
  final String column9;

  UserModel({
    required this.timestamp,
    required this.name,
    required this.registerNumber,
    required this.emailId,
    required this.department,
    required this.year,
    required this.sec,
    required this.phoneNumber,
    required this.passportSizePhoto,
    required this.emailAddress,
    required this.column9,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'name': name,
      'registerNumber': registerNumber,
      'emailId': emailId,
      'department': department,
      'year': year,
      'sec': sec,
      'phoneNumber': phoneNumber,
      'passportSizePhoto': passportSizePhoto,
      'emailAddress': emailAddress,
      'column9': column9,
    };
  }

  // Create from Map (for reading from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      timestamp: map['timestamp'] ?? '',
      name: map['name'] ?? '',
      registerNumber: map['registerNumber'] ?? 0,
      emailId: map['emailId'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      sec: map['sec'] ?? '',
      phoneNumber: map['phoneNumber'] ?? 0,
      passportSizePhoto: map['passportSizePhoto'] ?? '',
      emailAddress: map['emailAddress'] ?? '',
      column9: map['column9'] ?? '',
    );
  }

  // Copy with method for updating
  UserModel copyWith({
    String? timestamp,
    String? name,
    int? registerNumber,
    String? emailId,
    String? department,
    String? year,
    String? sec,
    int? phoneNumber,
    String? passportSizePhoto,
    String? emailAddress,
    String? column9,
  }) {
    return UserModel(
      timestamp: timestamp ?? this.timestamp,
      name: name ?? this.name,
      registerNumber: registerNumber ?? this.registerNumber,
      emailId: emailId ?? this.emailId,
      department: department ?? this.department,
      year: year ?? this.year,
      sec: sec ?? this.sec,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passportSizePhoto: passportSizePhoto ?? this.passportSizePhoto,
      emailAddress: emailAddress ?? this.emailAddress,
      column9: column9 ?? this.column9,
    );
  }
}