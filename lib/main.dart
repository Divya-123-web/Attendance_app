import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// Providers
import 'provider/attendance_provider.dart';
import 'provider/dashboard_provider.dart';
import 'provider/data_entry_provider.dart';

// Screens
import 'screens/registration_screen.dart';
import 'screens/teacher_login_screen.dart';
import 'provider/hod_provider.dart';
import 'screens/hod_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

   {
    await Firebase.initializeApp(
    );
  }

  runApp(const SmartAttendanceApp());
}

class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AttendanceProvider: manages student registration + face + location
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        // DashboardProvider: manages teacher login + attendance dashboard
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => HodProvider()),
        // DataEntryProvider: manages data entry state
        ChangeNotifierProvider(create: (_) => DataEntryProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Attendance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF6C63FF),
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            secondary: Color(0xFF3F3D56),
          ),
        ),
        home: const RoleSelectorScreen(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ROLE SELECTOR SCREEN
// First screen user sees — choose Student or Teacher
// ─────────────────────────────────────────────────────────────
class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
  // Image.network("https://drive.google.com/file/d/13WaEg1sUKKrvvppj0-YmKtwaaddLWqaX/view?usp=share_link", height: 100,width: 100),              // ── App Logo ──
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Smart Attendance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Who are you?',
                style: TextStyle(color: Colors.white38, fontSize: 15),
              ),
              const SizedBox(height: 56),

              // ── Student Button ──
              _roleButton(
                context,
                label: "I'm a Student",
                subtitle: 'Mark my attendance',
                icon: Icons.face_retouching_natural,
                color: const Color(0xFF6C63FF),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegistrationScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Teacher Button ──
              _roleButton(
                context,
                label: "I'm a Teacher",
                subtitle: 'View attendance dashboard',
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFF3ECFCF),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherLoginScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

// ── HOD Button ──
_roleButton(
  context,
  label: "I'm a HOD",
  subtitle: 'Department-level dashboard',
  icon: Icons.account_balance_rounded,
  color: const Color(0xFFFFB347),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const HodLoginScreen(),
    ),
  ),
),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),

            // Label + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}