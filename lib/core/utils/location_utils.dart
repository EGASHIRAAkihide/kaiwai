import 'dart:math';

/// Pure-Dart proximity utilities — fully testable without platform channels.
///
/// The live map ([MapScreen]) uses [Geolocator.distanceBetween] which delegates
/// to OS-level GPS.  This class provides the same Haversine calculation as a
/// plain Dart function so that proximity rules can be unit-tested without a
/// device or emulator.
class LocationUtils {
  LocationUtils._();

  /// Haversine great-circle distance in **metres** between two WGS-84 points.
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Returns `true` when the user position is within [radiusMeters] of the
  /// spot centre.  Boundary (distance == radius) counts as **inside**.
  static bool isInsideSpot({
    required double userLat,
    required double userLng,
    required double spotLat,
    required double spotLng,
    required double radiusMeters,
  }) {
    final distance = haversineDistance(userLat, userLng, spotLat, spotLng);
    return distance <= radiusMeters;
  }

  static double _toRad(double deg) => deg * pi / 180.0;
}
