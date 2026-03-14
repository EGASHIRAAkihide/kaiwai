import 'package:flutter_test/flutter_test.dart';
import 'package:kaiwai/core/utils/location_utils.dart';

void main() {
  // ── haversineDistance ──────────────────────────────────────────────────────

  group('LocationUtils.haversineDistance', () {
    test('returns 0 when both points are identical', () {
      final d = LocationUtils.haversineDistance(
        35.6762, 139.6503, 35.6762, 139.6503,
      );
      expect(d, 0.0);
    });

    test('approximates ~111 km per degree of latitude at the equator', () {
      final d = LocationUtils.haversineDistance(0.0, 0.0, 1.0, 0.0);
      // WGS-84 degree of latitude ≈ 111 195 m; allow ±200 m tolerance
      expect(d, closeTo(111195, 200));
    });

    test('is symmetric — A→B equals B→A', () {
      final ab = LocationUtils.haversineDistance(
        35.6762, 139.6503, 34.6937, 135.5023,
      );
      final ba = LocationUtils.haversineDistance(
        34.6937, 135.5023, 35.6762, 139.6503,
      );
      expect(ab, closeTo(ba, 0.001));
    });

    test('handles antipodal points (~20 015 km)', () {
      final d = LocationUtils.haversineDistance(0.0, 0.0, 0.0, 180.0);
      expect(d, closeTo(20015087, 5000));
    });
  });

  // ── isInsideSpot — proximity decision logic ───────────────────────────────

  group('LocationUtils.isInsideSpot', () {
    // Reference spot: Tokyo Station area, 300 m radius
    const spotLat = 35.6812;
    const spotLng = 139.7671;
    const radius = 300.0;

    // Approximate metres per degree of latitude at this location
    const metersPerDegLat = 111195.0;

    test('Case A — user exactly on spot coordinates → inside', () {
      expect(
        LocationUtils.isInsideSpot(
          userLat: spotLat,
          userLng: spotLng,
          spotLat: spotLat,
          spotLng: spotLng,
          radiusMeters: radius,
        ),
        isTrue,
      );
    });

    test('Case B — user 299 m away from a 300 m-radius spot → inside', () {
      // Shift user ~299 m north along the latitude axis
      const userLat = spotLat + (299.0 / metersPerDegLat);
      expect(
        LocationUtils.isInsideSpot(
          userLat: userLat,
          userLng: spotLng,
          spotLat: spotLat,
          spotLng: spotLng,
          radiusMeters: radius,
        ),
        isTrue,
      );
    });

    test('Case C — user 301 m away from a 300 m-radius spot → outside', () {
      // Shift user ~301 m north along the latitude axis
      const userLat = spotLat + (301.0 / metersPerDegLat);
      expect(
        LocationUtils.isInsideSpot(
          userLat: userLat,
          userLng: spotLng,
          spotLat: spotLat,
          spotLng: spotLng,
          radiusMeters: radius,
        ),
        isFalse,
      );
    });

    test('boundary edge — user at exactly radius distance → inside', () {
      const userLat = spotLat + (radius / metersPerDegLat);
      // Haversine introduces a small floating-point spread; allow ±0.5 m
      final dist = LocationUtils.haversineDistance(
        userLat, spotLng, spotLat, spotLng,
      );
      // Verify the distance is within ±0.5 m of the radius
      expect(dist, closeTo(radius, 0.5));
      // isInsideSpot uses <=, so distance == radius counts as inside
      expect(
        LocationUtils.isInsideSpot(
          userLat: userLat,
          userLng: spotLng,
          spotLat: spotLat,
          spotLng: spotLng,
          radiusMeters: dist, // use exact computed distance as radius
        ),
        isTrue,
      );
    });

    test('zero-radius spot — user on the exact coordinate → inside', () {
      expect(
        LocationUtils.isInsideSpot(
          userLat: spotLat,
          userLng: spotLng,
          spotLat: spotLat,
          spotLng: spotLng,
          radiusMeters: 0,
        ),
        isTrue,
      );
    });

    test('zero-radius spot — user 1 m away → outside', () {
      const userLat = spotLat + (1.0 / metersPerDegLat);
      expect(
        LocationUtils.isInsideSpot(
          userLat: userLat,
          userLng: spotLng,
          spotLat: spotLat,
          spotLng: spotLng,
          radiusMeters: 0,
        ),
        isFalse,
      );
    });
  });
}
