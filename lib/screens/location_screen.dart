// location_screen.dart
// SCREEN 3: Verifies student's GPS location against classroom geofence.
// Shows distance from classroom and whether they're inside/outside.

import 'package:attendanceapp/provider/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import 'success_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _verificationStarted = false;

  @override
  void initState() {
    super.initState();
    // Pulsing animation for the location pin
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _verifyLocation() async {
    setState(() => _verificationStarted = true);

    final provider = context.read<AttendanceProvider>();
    final locationSuccess = await provider.verifyLocation();

    if (!locationSuccess || !mounted) return;

    // Both face and location verified — mark attendance
    final attendanceSuccess = await provider.markAttendance();

    if (attendanceSuccess && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Location Verification',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProgressBar(3),
                  const SizedBox(height: 16),
                  const Text(
                    'Step 3 of 3 — Location Verification',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // Animated location icon
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6C63FF).withOpacity(0.3),
                            const Color(0xFF6C63FF).withOpacity(0.0),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF6C63FF),
                        size: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Classroom Geofencing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Classroom boundary info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.radar,
                          'Geofence Radius',
                          '${LocationService.geofenceRadiusMeters.toInt()} meters',
                        ),
                        const Divider(color: Colors.white12),
                        _buildInfoRow(
                          Icons.place,
                          'Classroom Center',
                          '${LocationService.classroomLatitude.toStringAsFixed(4)}, '
                          '${LocationService.classroomLongitude.toStringAsFixed(4)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location result (shown after verification)
                  if (provider.locationResult != null) ...[
                    _buildLocationResultCard(provider.locationResult!),
                    const SizedBox(height: 16),
                  ],

                  // Error message
                  if (provider.errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_off, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Spacer(),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _verifyLocation,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        provider.isLoading
                            ? 'Verifying location...'
                            : _verificationStarted
                                ? 'Try Again'
                                : 'Verify My Location',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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

  // Shows GPS result after location check
  Widget _buildLocationResultCard(LocationResult result) {
    final isInside = result.isInsideGeofence;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInside
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInside ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isInside ? Icons.check_circle : Icons.cancel,
            color: isInside ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInside ? 'Inside Classroom ✓' : 'Outside Classroom ✗',
                  style: TextStyle(
                    color: isInside ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Distance: ${result.distanceFromClassroom.toStringAsFixed(1)}m from center',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white54)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final isActive = step <= currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF6C63FF) : Colors.white12,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}