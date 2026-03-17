import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/spot.dart';

/// Fetches spot data from Supabase.
///
/// PostGIS geography columns cannot be read directly via REST as lat/lng.
/// This repository calls the `get_spots_with_coords` RPC function which
/// extracts coordinates server-side using ST_Y / ST_X.
///
/// ── Required Supabase SQL (run once) ─────────────────────────────────────
/// ```sql
/// CREATE OR REPLACE FUNCTION get_spots_with_coords()
/// RETURNS TABLE (
///   id            uuid,
///   name          text,
///   radius_meters int,
///   leader_id     uuid,
///   description   text,
///   created_at    timestamptz,
///   latitude      double precision,
///   longitude     double precision,
///   city_name     text,        -- global metadata
///   country_code  char(2),
///   timezone_id   text
/// )
/// LANGUAGE sql SECURITY DEFINER AS $$
///   SELECT id, name, radius_meters, leader_id, description, created_at,
///          ST_Y(location::geometry) AS latitude,
///          ST_X(location::geometry) AS longitude,
///          city_name, country_code, timezone_id
///   FROM spots;
/// $$;
/// ```
///
/// ── Offline Caching Strategy ──────────────────────────────────────────────
/// International travellers face intermittent connectivity. The recommended
/// pattern is a **write-through cache** implemented as a repository wrapper:
///
///   NetworkLayer (SpotRepository)
///       ↕  on success → write to cache
///       ↕  on error   → read stale from cache
///   CacheLayer (CachedSpotRepository)
///       ↕
///   LocalStore (Hive / sqflite)
///
/// WHY Hive over sqflite for this use case:
///   • Spots are fetched as a single flat list — no relational joins needed.
///   • Hive boxes store typed objects directly with zero boilerplate.
///   • Hive is faster for small datasets (no SQL parse overhead).
///   • sqflite is better when you need complex queries or foreign-key joins
///     (e.g., if you later join spots with check_ins locally).
///
/// To activate caching, add to pubspec.yaml:
///   hive_flutter: ^1.1.0
///
/// Then replace `SpotRepository()` with `CachedSpotRepository()` at all
/// call sites (currently only `_MapScreenState`).
///
/// See [CachedSpotRepository] below for the full implementation shell.
class SpotRepository {
  SpotRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches all spots with extracted lat/lng coordinates and global metadata.
  Future<List<Spot>> fetchSpots() async {
    debugPrint('[SpotRepository] fetchSpots → calling RPC get_spots_with_coords');
    final response = await _client.rpc('get_spots_with_coords');
    debugPrint('[SpotRepository] fetchSpots → raw response type: ${response.runtimeType}');
    debugPrint('[SpotRepository] fetchSpots → raw response: $response');

    final list = (response as List<dynamic>).cast<Map<String, dynamic>>();
    debugPrint('[SpotRepository] fetchSpots → ${list.length} rows returned');

    final spots = <Spot>[];
    for (final json in list) {
      try {
        spots.add(Spot.fromJson(json));
      } catch (e) {
        debugPrint('[SpotRepository] fetchSpots → parse error: $json\n  $e');
      }
    }
    return spots;
  }

  /// Creates a new spot via the `create_spot` Supabase RPC.
  ///
  /// The RPC constructs the PostGIS `geography(POINT)` column server-side
  /// via `ST_MakePoint(p_lng, p_lat)::geography`, so plain lat/lng doubles
  /// are all that is required from the client.
  ///
  /// Returns the UUID of the newly created spot.
  Future<String> createSpot({
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String? description,
    String? city,
    String? country,
  }) async {
    debugPrint('[SpotRepository] createSpot → name=$name, lat=$latitude, lng=$longitude');
    final response = await _client.rpc('create_spot', params: {
      'p_name': name,
      'p_lat': latitude,
      'p_lng': longitude,
      'p_radius_m': radiusMeters,
      'p_description': description,
      'p_city': city,
      'p_country': country,
    });
    debugPrint('[SpotRepository] createSpot → new spot id: $response');
    return response as String;
  }

  /// Fetches spots within [radiusMeters] of the given coordinates.
  ///
  /// Required Supabase SQL:
  /// ```sql
  /// CREATE OR REPLACE FUNCTION get_nearby_spots(
  ///   lat       double precision,
  ///   lng       double precision,
  ///   radius_m  int DEFAULT 5000
  /// )
  /// RETURNS TABLE (
  ///   id            uuid,
  ///   name          text,
  ///   radius_meters int,
  ///   leader_id     uuid,
  ///   description   text,
  ///   created_at    timestamptz,
  ///   latitude      double precision,
  ///   longitude     double precision,
  ///   city_name     text,
  ///   country_code  char(2),
  ///   timezone_id   text
  /// )
  /// LANGUAGE sql SECURITY DEFINER AS $$
  ///   SELECT id, name, radius_meters, leader_id, description, created_at,
  ///          ST_Y(location::geometry) AS latitude,
  ///          ST_X(location::geometry) AS longitude,
  ///          city_name, country_code, timezone_id
  ///   FROM spots
  ///   WHERE ST_DWithin(
  ///     location,
  ///     ST_MakePoint(lng, lat)::geography,
  ///     radius_m
  ///   );
  /// $$;
  /// ```
  Future<List<Spot>> fetchNearbySpots({
    required double latitude,
    required double longitude,
    int radiusMeters = 50000,
  }) async {
    debugPrint('[SpotRepository] fetchNearbySpots → lat=$latitude, lng=$longitude, radius=${radiusMeters}m');
    final response = await _client.rpc('get_nearby_spots', params: {
      'lat': latitude,
      'lng': longitude,
      'radius_m': radiusMeters,
    });
    debugPrint('[SpotRepository] fetchNearbySpots → raw response: $response');

    final list = (response as List<dynamic>).cast<Map<String, dynamic>>();
    debugPrint('[SpotRepository] fetchNearbySpots → ${list.length} rows returned');

    final spots = <Spot>[];
    for (final json in list) {
      try {
        spots.add(Spot.fromJson(json));
      } catch (e) {
        debugPrint('[SpotRepository] fetchNearbySpots → parse error: $json\n  $e');
      }
    }
    return spots;
  }
}

// ── Offline Cache Shell ───────────────────────────────────────────────────────
//
// This is a ready-to-activate implementation shell.
//
// Prerequisites:
//   1. Add `hive_flutter: ^1.1.0` to pubspec.yaml.
//   2. Register a Hive adapter for [Spot] (or store as JSON strings).
//   3. Call `await Hive.initFlutter()` in main() before Supabase.initialize.
//   4. Replace `SpotRepository()` with `CachedSpotRepository()` in MapScreen.
//
// The cache TTL is 5 minutes — long enough to survive a subway tunnel but
// short enough to pick up new spots when the user resurfaces.

// ignore_for_file: unused_element, unused_field

/// A [SpotRepository] wrapper that transparently caches spot lists locally.
///
/// On every successful network fetch the result is persisted to a Hive box.
/// On network failure (or while offline) the last-cached list is returned,
/// allowing the map to remain usable during intermittent connectivity.
class _CachedSpotRepository {
  _CachedSpotRepository({SpotRepository? network})
      : _network = network ?? SpotRepository();

  final SpotRepository _network;

  // Hive box name and cache key — keep stable across releases.
  static const _boxName = 'spot_cache';
  static const _spotsKey = 'all_spots';
  static const _spotsTimestampKey = 'all_spots_ts';
  static const _ttl = Duration(minutes: 5);

  // ── Public API (mirrors SpotRepository) ──────────────────────────────────

  Future<List<Spot>> fetchSpots() async {
    try {
      final fresh = await _network.fetchSpots();
      await _persist(_spotsKey, fresh);
      return fresh;
    } catch (e) {
      debugPrint('[CachedSpotRepository] network error, falling back to cache: $e');
      return _readCache(_spotsKey) ?? [];
    }
  }

  Future<List<Spot>> fetchNearbySpots({
    required double latitude,
    required double longitude,
    int radiusMeters = 50000,
  }) async {
    final cacheKey = 'nearby_${latitude.toStringAsFixed(3)}'
        '_${longitude.toStringAsFixed(3)}'
        '_$radiusMeters';
    final tsKey = '${cacheKey}_ts';

    // Return cache if still fresh
    final cached = _readCacheIfFresh(cacheKey, tsKey);
    if (cached != null) return cached;

    try {
      final fresh = await _network.fetchNearbySpots(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
      await _persist(cacheKey, fresh, tsKey: tsKey);
      return fresh;
    } catch (e) {
      debugPrint('[CachedSpotRepository] network error, falling back to cache: $e');
      return _readCache(cacheKey) ?? [];
    }
  }

  // ── Hive helpers ──────────────────────────────────────────────────────────
  //
  // TODO: Replace `dynamic` with typed Hive adapters once the adapter is
  // registered. Using JSON strings for now to avoid requiring code generation.

  Future<void> _persist(String key, List<Spot> spots, {String? tsKey}) async {
    // TODO: open box via `await Hive.openBox(_boxName)`
    // final box = Hive.box(_boxName);
    // final encoded = spots.map((s) => s.toJson()).toList();
    // await box.put(key, encoded);
    // await box.put(tsKey ?? '${key}_ts', DateTime.now().millisecondsSinceEpoch);
    debugPrint('[CachedSpotRepository] persisted ${spots.length} spots under "$key"');
  }

  List<Spot>? _readCache(String key) {
    // TODO:
    // final box = Hive.box(_boxName);
    // final raw = box.get(key) as List?;
    // return raw?.map((e) => Spot.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return null;
  }

  List<Spot>? _readCacheIfFresh(String key, String tsKey) {
    // TODO:
    // final box = Hive.box(_boxName);
    // final ts = box.get(tsKey) as int?;
    // if (ts == null) return null;
    // final age = DateTime.now().millisecondsSinceEpoch - ts;
    // if (age > _ttl.inMilliseconds) return null;
    // return _readCache(key);
    return null;
  }
}
