// attendance_record_model.dart
// Represents a single attendance log entry from Firestore.
// The 'attendance_logs' collection stores one document per attendance event.

class AttendanceRecord {
  final String id;
  final String registerNumber;
  final String studentName;
  final String studentEmail;
  final DateTime timestamp;
  final String date;           // "YYYY-MM-DD" for easy date filtering
  final bool isPresent;
  final bool manualOverride;   // true if teacher manually changed it

  AttendanceRecord({
    required this.id,
    required this.registerNumber,
    required this.studentName,
    required this.studentEmail,
    required this.timestamp,
    required this.date,
    this.isPresent = true,
    this.manualOverride = false,
  });

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceRecord(
      id: id,
      registerNumber: map['registerNumber'] ?? '',
      studentName: map['studentName'] ?? '',
      studentEmail: map['studentEmail'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      date: map['date'] ?? '',
      isPresent: map['isPresent'] ?? true,
      manualOverride: map['manualOverride'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'registerNumber': registerNumber,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'timestamp': timestamp.toIso8601String(),
      'date': date,
      'isPresent': isPresent,
      'manualOverride': manualOverride,
    };
  }

  // Creates a copy with modified fields
  AttendanceRecord copyWith({bool? isPresent, bool? manualOverride}) {
    return AttendanceRecord(
      id: id,
      registerNumber: registerNumber,
      studentName: studentName,
      studentEmail: studentEmail,
      timestamp: timestamp,
      date: date,
      isPresent: isPresent ?? this.isPresent,
      manualOverride: manualOverride ?? this.manualOverride,
    );
  }
}

// Summary model for dashboard stats card
class DashboardSummary {
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final double attendancePercentage;

  DashboardSummary({
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.attendancePercentage,
  });
}