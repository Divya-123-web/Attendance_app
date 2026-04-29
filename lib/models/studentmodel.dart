class StudentModel {
  final String registerNumber;
  final String name;
  final String email;

  StudentModel({
    required this.registerNumber,
    required this.name,
    required this.email,
  });

  factory StudentModel.fromMap(Map<String, dynamic> data) {
    return StudentModel(
      registerNumber: data['registerNumber'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }
}