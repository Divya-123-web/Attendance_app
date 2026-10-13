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
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
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

  void _showExportOptions(DashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14131F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.today, color: Colors.white),
                title: const Text('Export Day', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Download attendance for selected date', style: TextStyle(color: Colors.white60)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportRangeReport(provider, provider.selectedDate, provider.selectedDate, 'Day');
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_week, color: Colors.white),
                title: const Text('Export Week', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Download attendance for 7 days', style: TextStyle(color: Colors.white60)),
                onTap: () {
                  Navigator.pop(ctx);
                  final selected = DateTime.parse(provider.selectedDate);
                  final start = selected.subtract(const Duration(days: 6));
                  _exportRangeReport(provider, _formatDate(start), provider.selectedDate, 'Week');
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.white),
                title: const Text('Export Month', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Download attendance for the current month', style: TextStyle(color: Colors.white60)),
                onTap: () {
                  Navigator.pop(ctx);
                  final selected = DateTime.parse(provider.selectedDate);
                  final start = DateTime(selected.year, selected.month, 1);
                  final end = DateTime(selected.year, selected.month + 1, 0);
                  _exportRangeReport(provider, _formatDate(start), _formatDate(end), 'Month');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Export Single Student', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Download attendance history for one student', style: TextStyle(color: Colors.white60)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showStudentExportDialog(provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportRangeReport(
      DashboardProvider provider,
      String startDate,
      String endDate,
      String label) async {
    try {
      final records = await provider.getAttendanceInRange(startDate, endDate);
      if (records.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No records found for $label.')),
        );
        return;
      }
      final csvLines = _buildCsvForRange(records, provider.allStudents, startDate, endDate);
      final fileName = 'attendance_${label.toLowerCase()}_${startDate}_to_${endDate}.csv';
      final filePath = await _saveCsv(fileName, csvLines);
      if (!mounted) return;
      await _shareCsv(filePath, '$label attendance export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _showStudentExportDialog(DashboardProvider provider) async {
    final controller = TextEditingController();
    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1B2E),
          title: const Text('Export Student', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Register Number',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
    if (success == true && controller.text.trim().isNotEmpty) {
      await _exportStudentReport(provider, controller.text.trim());
    }
  }

  Future<void> _exportStudentReport(
      DashboardProvider provider, String registerNumber) async {
    try {
      final history = await provider.getStudentAttendanceHistory(registerNumber);
      if (history.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No attendance history found for $registerNumber.')),
        );
        return;
      }
      final csvLines = <String>['Date,Status,Register No,Name,Email,Time,Method'];
      for (final record in history) {
        final time = DateFormat('hh:mm a').format(record.timestamp);
        final method = record.manualOverride ? 'Manual' : 'Auto';
        csvLines.add(
          '${record.date},${record.isPresent ? 'Present' : 'Absent'},${record.registerNumber},${_escapeCsv(record.studentName)},${_escapeCsv(record.studentEmail)},$time,$method',
        );
      }
      final fileName = 'student_${registerNumber}_${DateTime.now().toIso8601String()}.csv';
      final filePath = await _saveCsv(fileName, csvLines);
      if (!mounted) return;
      await _shareCsv(filePath, 'Student attendance export for $registerNumber');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student export failed: $e')),
      );
    }
  }

  List<String> _buildCsvForRange(
      List<AttendanceRecord> records,
      List<StudentModel> allStudents,
      String startDate,
      String endDate) {
    final csvLines = <String>['Date,Status,Register No,Name,Email,Time,Method'];
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final byDate = <String, List<AttendanceRecord>>{};
    for (final record in records) {
      byDate.putIfAbsent(record.date, () => []).add(record);
    }
    for (var date = start; !date.isAfter(end); date = date.add(const Duration(days: 1))) {
      final key = DateFormat('yyyy-MM-dd').format(date);
      final todays = byDate[key] ?? [];
      final presentRegNos = todays.where((r) => r.isPresent).map((r) => r.registerNumber).toSet();
      for (final record in todays) {
        final time = DateFormat('hh:mm a').format(record.timestamp);
        final method = record.manualOverride ? 'Manual' : 'Auto';
        csvLines.add(
          '$key,Present,${record.registerNumber},${_escapeCsv(record.studentName)},${_escapeCsv(record.studentEmail)},$time,$method',
        );
      }
      final absentStudents = allStudents.where((s) => !presentRegNos.contains(s.registerNumber));
      for (final student in absentStudents) {
        csvLines.add(
          '$key,Absent,${student.registerNumber},${_escapeCsv(student.name)},${_escapeCsv(student.email)},,',
        );
      }
    }
    return csvLines;
  }

  Future<String> _saveCsv(String fileName, List<String> lines) async {
    final directory = await _getDownloadDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(lines.join('\n'));
    return file.path;
  }

  Future<void> _shareCsv(String filePath, String subject) async {
    final file = XFile(filePath);
    await Share.shareXFiles(
      [file],
      text: subject,
      subject: subject,
    );
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        final storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          final directories = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (directories != null && directories.isNotEmpty) {
            final downloads = directories.first;
            if (!await downloads.exists()) {
              await downloads.create(recursive: true);
            }
            return downloads;
          }
        }
      } catch (_) {
        // Continue to fallback directories if public downloads access fails.
      }

      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final downloadPath = Directory('${externalDir.path}/Download');
        if (!await downloadPath.exists()) {
          await downloadPath.create(recursive: true);
        }
        return downloadPath;
      }
    }

    return await getApplicationDocumentsDirectory();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
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
              IconButton(
                onPressed: () => _showExportOptions(provider),
                icon: const Icon(Icons.download, color: Color(0xFF6C63FF)),
                tooltip: 'Download attendance list',
              ),
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