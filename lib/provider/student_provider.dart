// This model represents a Student object throughout the app.
// It maps to a Firestore document.

class StudentModel {
  final String id;
  final String name;
  final String registerNumber;
  final String email;
  final String? faceImageUrl; // URL of face image stored in Firebase Storage
  bool isFaceRegistered;

  StudentModel({
    required this.id,
    required this.name,
    required this.registerNumber,
    required this.email,
    this.faceImageUrl,
    this.isFaceRegistered = false,
  });

  // Convert StudentModel → Map (to save to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'registerNumber': registerNumber,
      'email': email,
      'faceImageUrl': faceImageUrl,
      'isFaceRegistered': isFaceRegistered,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Convert Firestore document → StudentModel
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      registerNumber: map['registerNumber'] ?? '',
      email: map['email'] ?? '',
      faceImageUrl: map['faceImageUrl'],
      isFaceRegistered: map['isFaceRegistered'] ?? false,
    );
  }
}