// hod_model.dart
// Represents a Head of Department account.
// HOD has higher privileges than Teacher —
// can see ALL classes, ALL teachers, department-wide stats.

class HodModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final List<String> managedClasses; // e.g. ['CS-A', 'CS-B', 'IT-A']

  HodModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    this.managedClasses = const [],
  });

  factory HodModel.fromMap(Map<String, dynamic> map) {
    return HodModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      managedClasses: List<String>.from(map['managedClasses'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'managedClasses': managedClasses,
      'role': 'hod', // role field to distinguish from teachers in Firestore
    };
  }
}

// Department-wide summary for HOD dashboard
class DepartmentSummary {
  final String className;
  final int totalStudents;
  final int presentToday;
  final double attendanceRate;

  DepartmentSummary({
    required this.className,
    required this.totalStudents,
    required this.presentToday,
    required this.attendanceRate,
  });
}