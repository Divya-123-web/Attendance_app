// student_detail_screen.dart
// Shows full attendance history for a single student.
// Teacher can see all past records and override any of them.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_record_model.dart';
import '../../services/dashboard_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final String registerNumber;
  final String studentName;

  const StudentDetailScreen({
    super.key,
    required this.registerNumber,
    required this.studentName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final DashboardService _service = DashboardService();
  List<AttendanceRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      _history = await _service.getStudentHistory(widget.registerNumber);
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Calculate attendance percentage for this student
  double get _attendancePercentage {
    if (_history.isEmpty) return 0;
    final present = _history.where((r) => r.isPresent).length;
    return present / _history.length * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0E17),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.studentName,
            style: const TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: const Color(0xFF6C63FF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student summary card
                    _buildSummaryCard(),
                    const SizedBox(height: 24),

                    const Text('Attendance History',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // History list
                    if (_history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No attendance records yet',
                              style: TextStyle(color: Colors.white38)),
                        ),
                      )
                    else
                      ..._history.map((record) =>
                          _buildHistoryItem(record)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final present = _history.where((r) => r.isPresent).length;
    final percentage = _attendancePercentage;
    final color = percentage >= 75
        ? Colors.green
        : percentage >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.3),
            const Color(0xFF1C1B2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Circular percentage indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 7,
                ),
                Text('${percentage.toInt()}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.studentName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(widget.registerNumber,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 8),
                Text('$present / ${_history.length} classes attended',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    percentage >= 75
                        ? '✓ Good Standing'
                        : percentage >= 50
                            ? '⚠ At Risk'
                            : '✗ Poor Attendance',
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record) {
    final dateStr =
        DateFormat('MMM d, yyyy').format(record.timestamp);
    final timeStr = DateFormat('hh:mm a').format(record.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.isPresent
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            record.isPresent ? Icons.check_circle : Icons.cancel,
            color: record.isPresent ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                Text(timeStr,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          if (record.manualOverride)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Override',
                  style:
                      TextStyle(color: Colors.orange, fontSize: 10)),
            ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: record.isPresent
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: record.isPresent ? Colors.green : Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}