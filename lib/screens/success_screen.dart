// success_screen.dart
// Final screen shown after attendance is successfully marked.
// Displays confirmation with student details.

import 'package:attendanceapp/provider/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'registration_screen.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.read<AttendanceProvider>().student;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon with animated ring
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.15),
                    border: Border.all(color: Colors.green, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Attendance Marked!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Email report sent to teacher ✉',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Student details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Name', student?.name ?? '—'),
                      const SizedBox(height: 12),
                      _detailRow('Register No', student?.registerNumber ?? '—'),
                      const SizedBox(height: 12),
                      _detailRow('Email', student?.email ?? '—'),
                      const SizedBox(height: 12),
                      _detailRow(
                        'Time',
                        student?.attendanceTime != null
                            ? '${student!.attendanceTime!.hour}:'
                              '${student.attendanceTime!.minute.toString().padLeft(2, '0')}'
                            : '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Verification badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _badge(Icons.face_retouching_natural, 'Face Verified', Colors.blue),
                    const SizedBox(width: 16),
                    _badge(Icons.location_on, 'Location Verified', Colors.green),
                  ],
                ),
                const SizedBox(height: 40),

                // Mark attendance for another student
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      // Reset state and go back to start
                      context.read<AttendanceProvider>().reset();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistrationScreen(),
                        ),
                        (route) => false, // Remove all previous routes
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Mark Another Student',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}