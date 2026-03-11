// location_service.dart
// Handles GPS location and Geofencing.
//
// Geofencing = defining a virtual circular boundary around a location.
// If student's GPS coordinates fall within that circle → they're "inside".
//
// Formula used: Haversine formula (calculates distance between two GPS points)

import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {

  // ─────────────────────────────────────────
  // CLASSROOM GEOFENCE CONFIGURATION
  // Change these to your actual classroom coordinates
  // ─────────────────────────────────────────
  static const double classroomLatitude = 13.0827;   // Example: Chennai
  static const double classroomLongitude = 80.2707;  // Example: Chennai
  static const double geofenceRadiusMeters = 100.0;  // 100 meter radius

  // ─────────────────────────────────────────
  // 1. REQUEST LOCATION PERMISSION
  // Must be called before getting location
  // ─────────────────────────────────────────
  Future<bool> requestPermission() async {
    // Check if location services are enabled on device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location services disabled');
      return false;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // If denied, request it
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If permanently denied, open app settings
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  // ─────────────────────────────────────────
  // 2. GET CURRENT GPS POSITION
  // Returns latitude and longitude
  // ─────────────────────────────────────────
  Future<Position> getCurrentPosition() async {
    try {
      // LocationAccuracy.high = uses GPS (most accurate)
      // LocationAccuracy.low = uses network/WiFi (less battery)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  // ─────────────────────────────────────────
  // 3. CHECK IF STUDENT IS INSIDE CLASSROOM
  // Uses Haversine distance formula
  // ─────────────────────────────────────────
  Future<LocationResult> verifyLocation() async {
    try {
      // Get student's current GPS position
      final position = await getCurrentPosition();

      // Calculate distance between student and classroom center
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        classroomLatitude,
        classroomLongitude,
      );

      print('📍 Student location: ${position.latitude}, ${position.longitude}');
      print('📏 Distance from classroom: ${distance.toStringAsFixed(1)}m');
      print('🎯 Geofence radius: ${geofenceRadiusMeters}m');

      final isInside = distance <= geofenceRadiusMeters;

      return LocationResult(
        isInsideGeofence: isInside,
        distanceFromClassroom: distance,
        studentLatitude: position.latitude,
        studentLongitude: position.longitude,
      );
    } catch (e) {
      throw Exception('Location verification failed: $e');
    }
  }

  // ─────────────────────────────────────────
  // HAVERSINE FORMULA
  // Calculates distance (meters) between two GPS coordinates
  // Accounts for Earth's curvature
  // ─────────────────────────────────────────
  double _calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const earthRadius = 6371000.0; // Earth's radius in meters

    // Convert degrees to radians
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    // Haversine formula
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
        cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in meters
  }

  double _toRadians(double degrees) => degrees * (pi / 180);
}

// Data class to hold location verification results
class LocationResult {
  final bool isInsideGeofence;
  final double distanceFromClassroom;
  final double studentLatitude;
  final double studentLongitude;

  LocationResult({
    required this.isInsideGeofence,
    required this.distanceFromClassroom,
    required this.studentLatitude,
    required this.studentLongitude,
  });
}