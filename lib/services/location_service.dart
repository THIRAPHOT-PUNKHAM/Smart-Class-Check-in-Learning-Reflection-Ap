import 'package:geolocator/geolocator.dart';

/// LocationService
/// ---------------
/// Handles all GPS / location logic using the geolocator package.
///
/// Key responsibilities:
///   1. Check and request Location permission at runtime (NFR requirement).
///   2. Verify that the device location service (GPS) is enabled.
///   3. Return the current device position (lat / lng).
///
/// Usage:
///   final service = LocationService();
///   final position = await service.getCurrentPosition();
///   print('${position.latitude}, ${position.longitude}');

class LocationService {
  // ------------------------------------------------------------------
  // Permission & Service checks
  // ------------------------------------------------------------------

  /// Returns true if location permission is granted (or limited on iOS).
  /// Requests permission if it has not been determined yet.
  /// Throws [LocationPermissionDeniedException] if the user permanently
  /// denies permission.
  Future<bool> checkAndRequestPermission() async {
    // 1. Is device GPS/location service enabled at all?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    // 2. Check current permission status.
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. Request if not yet determined.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 4. Permanently denied → direct user to app settings.
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException(
        'Location permission is permanently denied. '
        'Please enable it in Settings.',
      );
    }

    // whileInUse or always → OK to proceed.
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ------------------------------------------------------------------
  // Get current position
  // ------------------------------------------------------------------

  /// Requests the device's current GPS position.
  ///
  /// Calls [checkAndRequestPermission] first, so callers do NOT need to
  /// check permissions separately before calling this method.
  ///
  /// Returns a [Position] object containing latitude and longitude.
  ///
  /// Throws:
  ///   - [LocationServiceDisabledException] if GPS is off.
  ///   - [LocationPermissionDeniedException] if permission is denied.
  ///   - [LocationTimeoutException] if the fix takes too long.
  Future<Position> getCurrentPosition() async {
    // Ensure permissions are in order before requesting a fix.
    await checkAndRequestPermission();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        // High accuracy uses GPS; acceptable on mobiles for class check-in.
        accuracy: LocationAccuracy.high,
        // Stop after this distance change (not relevant for one-shot, but good default).
        distanceFilter: 0,
      ),
    );
  }

  // ------------------------------------------------------------------
  // Utility helpers
  // ------------------------------------------------------------------

  /// Returns a human-readable string of the position for display / logging.
  static String formatPosition(Position position) {
    return 'Lat: ${position.latitude.toStringAsFixed(6)}, '
        'Lng: ${position.longitude.toStringAsFixed(6)}';
  }

  /// Returns true when location permission has already been granted without
  /// triggering a new dialog. Useful for showing UI state.
  Future<bool> hasPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}

// ------------------------------------------------------------------
// Custom exceptions
// ------------------------------------------------------------------

/// Thrown when the device location service (GPS) is switched off.
class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();

  @override
  String toString() =>
      'LocationServiceDisabledException: '
      'Location services are disabled. Please enable GPS.';
}

/// Thrown when the user permanently refuses location access.
class LocationPermissionDeniedException implements Exception {
  final String message;
  const LocationPermissionDeniedException(this.message);

  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}
