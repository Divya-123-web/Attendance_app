// location_service.dart
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

// ─────────────────────────────────────────
// TYPED ERRORS — no more generic exceptions
// ─────────────────────────────────────────
enum LocationErrorType {
  serviceDisabled,   // GPS/Location turned off at device level
  permissionDenied,  // User said "deny" when prompted
  permissionDeniedForever, // User chose "never ask again"
  locationTimeout,   // GPS couldn't get a fix in time
  unknown,
}

class LocationException implements Exception {
  final LocationErrorType type;
  final String message;
  const LocationException(this.type, this.message);

  @override
  String toString() => 'LocationException(${type.name}): $message';
}

// ─────────────────────────────────────────
// RESULT MODEL
// ─────────────────────────────────────────
class LocationResult {
  final bool isInsideGeofence;
  final double distanceFromClassroom; // metres
  final double studentLatitude;
  final double studentLongitude;
  final DateTime timestamp;

  const LocationResult({
    required this.isInsideGeofence,
    required this.distanceFromClassroom,
    required this.studentLatitude,
    required this.studentLongitude,
    required this.timestamp,
  });

  @override
  String toString() =>
      'LocationResult(inside: $isInsideGeofence, '
      'distance: ${distanceFromClassroom.toStringAsFixed(1)}m)';
}

// ─────────────────────────────────────────
// MAIN SERVICE
// ─────────────────────────────────────────
class LocationService {

  // Change these to your actual classroom coordinates
  static const double classroomLatitude  = 12.9828082; // 13.0827;
  static const double classroomLongitude = 80.213865; //80.2707;
  static const double geofenceRadiusMeters = 2000.0;

  // ─── 1. PERMISSION ───────────────────────
  /// Call this once before any location work.
  /// Throws [LocationException] with a specific type so the UI
  /// can show the right message / action button.
  Future<void> ensurePermission() async {
    // Check if the device's location service is on at all
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationErrorType.serviceDisabled,
        'Location services are disabled. Please turn on GPS in device settings.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // First-time or previously denied → prompt
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationErrorType.permissionDenied,
        'Location permission was denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      // Can't request again — must send user to Settings
      await Geolocator.openAppSettings();
      throw const LocationException(
        LocationErrorType.permissionDeniedForever,
        'Location permission is permanently denied. '
        'Please enable it in App Settings.',
      );
    }

    // At this point: whileInUse or always — both are fine
  }

  // ─── 2. ONE-SHOT POSITION ────────────────
  /// Gets a single GPS fix.
  /// Uses [LocationAccuracy.high] (real GPS chip, not network).
  /// 15-second timeout prevents the app hanging forever.
  Future<Position> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } on TimeoutException {
      throw const LocationException(
        LocationErrorType.locationTimeout,
        'Could not get GPS fix within 15 seconds. '
        'Move to an open area and try again.',
      );
    } catch (e) {
      throw LocationException(
        LocationErrorType.unknown,
        'Failed to get location: $e',
      );
    }
  }

  // ─── 3. LIVE STREAM ──────────────────────
  /// Returns a continuous stream of [LocationResult].
  /// Good for a "live attendance" screen that auto-updates.
  ///
  /// Usage:
  ///   locationService.positionStream.listen((result) { ... });
  Stream<LocationResult> get positionStream {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // only emit when student moves ≥ 5 m
    );
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((position) => _buildResult(position));
  }

  static double get classroomLng => classroomLongitude;

  static double get classroomLat => classroomLatitude;

  static double get allowedRadius => geofenceRadiusMeters;

  // ─── 4. FULL VERIFY (permission + fix + geofence) ───
  /// The main method your attendance button should call.
  Future<LocationResult> verifyLocation() async {
    await ensurePermission();
    final position = await getCurrentPosition();
    print('📍 Got position: ${position.latitude}, ${position.longitude} '
          'with accuracy ${position.accuracy}m');
    return _buildResult(position);
  }

  // ─────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────
  LocationResult _buildResult(Position position) {
    final distance = _haversineDistance(
      position.latitude, position.longitude,
      classroomLatitude, classroomLongitude,
    );

    return LocationResult(
      isInsideGeofence: distance <= geofenceRadiusMeters,
      distanceFromClassroom: distance,
      studentLatitude: position.latitude,
      studentLongitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }

  /// Haversine formula — great-circle distance between two GPS points.
  /// Accounts for Earth's curvature; accurate up to ~0.3% error.
  double _haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const earthRadius = 6371000.0; // metres

    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * (pi / 180);

  Future<bool> requestPermission() async {
    try {
      await ensurePermission();
      return true;
    } on LocationException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}