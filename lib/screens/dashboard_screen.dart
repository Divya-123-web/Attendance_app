// dashboard_screen.dart
// Main teacher dashboard. Shows:
// - Summary stats (total/present/absent/percentage)
// - 7-day bar chart
// - Date picker
// - Real-time student list with search + filter
// - Manual override per student

import 'package:attendanceapp/provider/dashboard_provider.dart';
import 'package:attendanceapp/provider/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/attendance_record_model.dart';
import 'student_detail_screen.dart';
import 'teacher_login_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Two tabs: Present | Absent
    _tabController = TabController(length: 3, vsync: this);
    // Initialize dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initializeDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final provider = context.read<DashboardProvider>();
    final parsed = DateTime.parse(provider.selectedDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        // Dark-themed date picker
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              surface: Color(0xFF1C1B2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.selectDate(picked.toIso8601String().split('T')[0]);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1B2E),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DashboardProvider>().signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final summary = provider.summary;
        final dateLabel = DateFormat('EEEE, MMM d')
            .format(DateTime.parse(provider.selectedDate));

        return Scaffold(
          backgroundColor: const Color(0xFF0F0E17),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0E17),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(dateLabel,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
            actions: [
              // Date picker button
              IconButton(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today,
                    color: Color(0xFF6C63FF)),
                tooltip: 'Pick Date',
              ),
              IconButton(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.white38),
                tooltip: 'Sign Out',
              ),
            ],
          ),
          body: provider.isLoading
              ? _buildShimmerLoader()
              : RefreshIndicator(
                  onRefresh: provider.initializeDashboard,
                  color: const Color(0xFF6C63FF),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // ── Stats Cards Row ──
                        _buildStatsRow(summary),

                        // ── Weekly Chart ──
                        _buildWeeklyChart(provider.weeklyData),

                        // ── Search Bar ──
                        _buildSearchBar(provider),

                        // ── Tab Bar ──
                        _buildTabBar(),

                        // ── Tab Content ──
                        SizedBox(
                          height: 500,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // All tab
                              _buildStudentList(
                                provider.attendanceRecords,
                                provider.absentStudents,
                                provider,
                                showAll: true,
                              ),
                              // Present tab
                              _buildStudentList(
                                provider.attendanceRecords
                                    .where((r) => r.isPresent)
                                    .toList(),
                                [],
                                provider,
                              ),
                              // Absent tab
                              _buildAbsentList(
                                  provider.absentStudents, provider),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  // ── STATS CARDS ──────────────────────────
  Widget _buildStatsRow(DashboardSummary summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _statCard('Total', summary.totalStudents.toString(),
              Icons.groups_rounded, const Color(0xFF6C63FF)),
          const SizedBox(width: 10),
          _statCard('Present', summary.presentCount.toString(),
              Icons.check_circle_outline, Colors.green),
          const SizedBox(width: 10),
          _statCard('Absent', summary.absentCount.toString(),
              Icons.cancel_outlined, Colors.redAccent),
          const SizedBox(width: 10),
          _statCard('Rate', '${summary.attendancePercentage.toInt()}%',
              Icons.pie_chart_outline, const Color(0xFF3ECFCF)),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── WEEKLY BAR CHART ─────────────────────
  Widget _buildWeeklyChart(Map<String, int> weekData) {
    if (weekData.isEmpty) return const SizedBox.shrink();

    final bars = weekData.entries.toList();
    final maxY =
        (weekData.values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('7-Day Attendance',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: const Color(0xFF6C63FF),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} present',
                          const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < bars.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                bars[idx].key,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: bars.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF3ECFCF),
                            ],
                          ),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH BAR ───────────────────────────
  Widget _buildSearchBar(DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: TextField(
        onChanged: provider.setSearchQuery,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by name or register number...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon:
              const Icon(Icons.search, color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF1C1B2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── TAB BAR ──────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFF6C63FF),
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Present'),
            Tab(text: 'Absent'),
          ],
        ),
      ),
    );
  }

  // ── PRESENT STUDENT LIST ─────────────────
  Widget _buildStudentList(
    List<AttendanceRecord> records,
    List<StudentModel> absentStudents,
    DashboardProvider provider, {
    bool showAll = false,
  }) {
    if (records.isEmpty) {
      return _buildEmptyState('No attendance records found');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (ctx, i) {
        final record = records[i];
        return _buildAttendanceCard(record, provider);
      },
    );
  }

  // ── ABSENT STUDENT LIST ──────────────────
  Widget _buildAbsentList(
      List<StudentModel> absent, DashboardProvider provider) {
    if (absent.isEmpty) {
      return _buildEmptyState('All students are present! 🎉');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: absent.length,
      itemBuilder: (ctx, i) {
        final student = absent[i];
        return _buildAbsentCard(student, provider);
      },
    );
  }

  // ── ATTENDANCE RECORD CARD ───────────────
  Widget _buildAttendanceCard(
      AttendanceRecord record, DashboardProvider provider) {
    final timeStr = DateFormat('hh:mm a').format(record.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: record.isPresent
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              record.isPresent ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
          child: Text(
            record.studentName.isNotEmpty
                ? record.studentName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: record.isPresent ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(record.studentName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.registerNumber,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12)),
            Text(timeStr,
                style: const TextStyle(
                    color: Colors.white24, fontSize: 11)),
            // if (record.manualOverride)
            //   const Text('⚙ Manual Override',
            //       style: TextStyle(
            //           color: Colors.orange,
            //           fontSize: 10,
            //           fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status badge
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
            const SizedBox(width: 8),
            // Override toggle
            GestureDetector(
              onTap: () => _showOverrideDialog(record, provider),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white24, size: 18),
            ),
          ],
        ),
        onTap: () {
          // Navigate to student detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(
                registerNumber: record.registerNumber,
                studentName: record.studentName,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── ABSENT STUDENT CARD ──────────────────
  Widget _buildAbsentCard(
      StudentModel student, DashboardProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.12),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(student.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(student.registerNumber,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: TextButton.icon(
          onPressed: () => _confirmManualMark(student, provider),
          icon: const Icon(Icons.add_circle_outline,
              size: 16, color: Color(0xFF3ECFCF)),
          label: const Text('Mark Present',
              style:
                  TextStyle(color: Color(0xFF3ECFCF), fontSize: 12)),
        ),
      ),
    );
  }

  // ── OVERRIDE DIALOG ──────────────────────
  void _showOverrideDialog(
      AttendanceRecord record, DashboardProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1B2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Override Attendance',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Change ${record.studentName}\'s attendance to '
          '${record.isPresent ? "Absent" : "Present"}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.overrideAttendance(record.id, !record.isPresent);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Confirm', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  // ── MANUAL MARK CONFIRM ──────────────────
  void _confirmManualMark(
      StudentModel student, DashboardProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1B2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Manually Mark Present',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Mark ${student.name} (${student.registerNumber}) as present manually?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.manuallyMarkPresent(student);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700),
            child: const Text('Mark Present', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, color: Colors.white12, size: 56),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }

  // ── SHIMMER LOADING ──────────────────────
  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1C1B2E),
      highlightColor: const Color(0xFF2A2940),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            6,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}