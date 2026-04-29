// student_dashboard_screen.dart
// Dashboard for students to view their attendance

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../provider/student_login_provider.dart';
import '../services/dashboard_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String registerNumber;
  final UserModel student;

  const StudentDashboardScreen({
    super.key,
    required this.registerNumber,
    required this.student,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final DashboardService _service = DashboardService();
  UserModel? _student;
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get student info
      _student = widget.student;

      // Get attendance history
      final history = await _service.getStudentHistory(widget.registerNumber);

      if (!mounted) return;

      setState(() {
        _attendanceHistory = history.map((record) => {
          'date': record.date,
          'isPresent': record.isPresent,
          'timestamp': record.timestamp,
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final presentCount = _attendanceHistory.where((record) => record['isPresent'] == true).length;
    final totalCount = _attendanceHistory.length;
    final attendancePercentage = totalCount > 0 ? (presentCount / totalCount * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Attendance',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<StudentLoginProvider>(context, listen: false).logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info
              if (_student != null) ...[
                Text(
                  'Welcome, ${_student!.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register Number: ${_student!.registerNumber}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
              ],

              // Attendance Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('Present', presentCount.toString(), Colors.green),
                    _summaryItem('Total', totalCount.toString(), Colors.blue),
                    _summaryItem('Percentage', '$attendancePercentage%', Colors.purple),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Attendance History
              const Text(
                'Attendance History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _attendanceHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'No attendance records found',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _attendanceHistory.length,
                        itemBuilder: (context, index) {
                          final record = _attendanceHistory[index];
                          final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(record['date']));
                          final isPresent = record['isPresent'] as bool;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Icon(
                                  isPresent ? Icons.check_circle : Icons.cancel,
                                  color: isPresent ? Colors.green : Colors.red,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}