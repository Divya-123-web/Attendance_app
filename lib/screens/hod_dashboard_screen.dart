// hod_dashboard_screen.dart
// Full department-level dashboard for HOD.
// Shows: dept stats, low attendance alerts,
// monthly chart, all students, teacher list.

import 'package:attendanceapp/provider/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../provider/hod_provider.dart';
import 'hod_login_screen.dart';
import '../services/hod_service.dart';


class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // HOD accent color — gold/amber
  static const Color hodColor = Color(0xFFFFB347);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HodProvider>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1B2E),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Sign out from HOD portal?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<HodProvider>().signOut();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HodLoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HodProvider>(
      builder: (context, provider, _) {
        final stats = provider.deptStats;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0E17),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0E17),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HOD Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text(
                  'Department Overview',
                  style: TextStyle(color: hodColor.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: provider.loadDashboard,
                icon: const Icon(Icons.refresh, color: Colors.white38),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.white38),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: hodColor))
              : RefreshIndicator(
                  onRefresh: provider.loadDashboard,
                  color: hodColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // ── HOD Identity Banner ──
                        _buildHodBanner(),

                        // ── Department Stats ──
                        _buildDeptStats(stats),

                        // ── Alert Banner (if any low attendance) ──
                        if (provider.lowAttendanceStudents.isNotEmpty)
                          _buildAlertBanner(provider),

                        // ── Monthly Chart ──
                        _buildMonthlyChart(provider.monthlyData),

                        // ── Threshold Slider ──
                        _buildThresholdSlider(provider),

                        // ── Tab Bar ──
                        _buildTabBar(),

                        // ── Tab Content ──
                        SizedBox(
                          height: 500,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 1: Low Attendance Alerts
                              _buildLowAttendanceTab(provider),
                              // Tab 2: All Students
                              _buildAllStudentsTab(provider),
                              // Tab 3: Teachers
                              _buildTeachersTab(provider),
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

  // ── HOD BANNER ───────────────────────────
  Widget _buildHodBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            hodColor.withOpacity(0.2),
            const Color(0xFF1C1B2E),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hodColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hodColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: hodColor, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Head of Department',
                    style: TextStyle(
                        color: hodColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('Full department visibility & control',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hodColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Admin+',
                style: TextStyle(
                    color: hodColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── DEPT STATS CARDS ─────────────────────
  Widget _buildDeptStats(Map<String, dynamic> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              _statCard('Total\nStudents',
                  '${stats['totalStudents'] ?? 0}',
                  Icons.groups_rounded, const Color(0xFF6C63FF)),
              const SizedBox(width: 10),
              _statCard('Present\nToday',
                  '${stats['presentToday'] ?? 0}',
                  Icons.check_circle_outline, Colors.green),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2
          Row(
            children: [
              _statCard('Today\'s\nRate',
                  '${(stats['todayRate'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.today_rounded, hodColor),
              const SizedBox(width: 10),
              _statCard('Overall\nRate',
                  '${(stats['overallRate'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.pie_chart_outline, const Color(0xFF3ECFCF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── ALERT BANNER ─────────────────────────
  Widget _buildAlertBanner(HodProvider provider) {
    final count = provider.lowAttendanceStudents.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count student${count > 1 ? 's' : ''} below ${provider.alertThreshold.toInt()}% attendance!',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const Text(
                  'Immediate attention required — see Alerts tab',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── MONTHLY CHART ─────────────────────────
  Widget _buildMonthlyChart(Map<String, int> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();
    final maxY = data.values.isEmpty
        ? 10.0
        : (data.values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Monthly Attendance',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hodColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${DateTime.now().month}/${DateTime.now().year}',
                  style:
                      const TextStyle(color: hodColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: entries.asMap().entries.map((e) {
                      return FlSpot(
                        double.parse(e.value.key),
                        e.value.value.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFF6B35)],
                    ),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          hodColor.withOpacity(0.2),
                          hodColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── THRESHOLD SLIDER ─────────────────────
  Widget _buildThresholdSlider(HodProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: hodColor, size: 18),
              const SizedBox(width: 8),
              const Text('Alert Threshold',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${provider.alertThreshold.toInt()}%',
                  style: const TextStyle(
                      color: hodColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Students below this % will appear in Alerts tab',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: hodColor,
              inactiveTrackColor: Colors.white12,
              thumbColor: hodColor,
              overlayColor: hodColor.withOpacity(0.2),
            ),
            child: Slider(
              value: provider.alertThreshold,
              min: 50,
              max: 90,
              divisions: 8,
              onChanged: provider.setThreshold,
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ──────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: hodColor,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: '⚠ Alerts'),
            Tab(text: 'Students'),
            Tab(text: 'Teachers'),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: LOW ATTENDANCE ALERTS ─────────
  Widget _buildLowAttendanceTab(HodProvider provider) {
    final list = provider.lowAttendanceStudents;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 56),
            const SizedBox(height: 12),
            Text(
              'All students above ${provider.alertThreshold.toInt()}%!',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        final student = item['student'] as StudentModel;
        final percentage = item['percentage'] as double;
        final attended = item['attended'] as int;
        final total = item['totalClasses'] as int;

        final color = percentage < 50
            ? Colors.red
            : percentage < 65
                ? Colors.orange
                : Colors.yellow;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1B2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // Circular percentage
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeWidth: 5,
                    ),
                    Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(student.registerNumber,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('$attended / $total classes attended',
                        style: TextStyle(color: color, fontSize: 12)),
                  ],
                ),
              ),
              // Risk badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  percentage < 50
                      ? 'Critical'
                      : percentage < 65
                          ? 'High Risk'
                          : 'At Risk',
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── TAB 2: ALL STUDENTS ──────────────────
  Widget _buildAllStudentsTab(HodProvider provider) {
    return StreamBuilder<List<StudentModel>>(
      stream: HodService().getAllStudentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: hodColor));
        }
        final students = snapshot.data!;
        if (students.isEmpty) {
          return const Center(
              child: Text('No students registered',
                  style: TextStyle(color: Colors.white38)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (ctx, i) {
            final s = students[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1B2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        const Color(0xFF6C63FF).withOpacity(0.15),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF6C63FF)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        Text(s.registerNumber,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.attendanceMarked
                          ? Colors.green.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.attendanceMarked ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: s.attendanceMarked
                            ? Colors.green
                            : Colors.red,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── TAB 3: TEACHERS ──────────────────────
  Widget _buildTeachersTab(HodProvider provider) {
    final teachers = provider.teachers;
    if (teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search,
                color: Colors.white12, size: 56),
            const SizedBox(height: 12),
            const Text('No teachers found',
                style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 8),
            const Text(
              'Add teachers via Firebase Console\n(users collection, role: teacher)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teachers.length,
      itemBuilder: (ctx, i) {
        final t = teachers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1B2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hodColor.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: hodColor.withOpacity(0.15),
                child: const Icon(Icons.person, color: hodColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'] ?? 'Teacher',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    Text(t['email'] ?? '',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hodColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Teacher',
                    style: TextStyle(color: hodColor, fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Need to import HodService in this file for the stream
