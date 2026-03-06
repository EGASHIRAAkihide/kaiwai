import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/spot.dart';

/// Fetches spot data from Supabase.
///
/// PostGIS geography columns cannot be read directly via REST as lat/lng.
/// This repository calls the `get_spots_with_coords` RPC function which
/// extracts coordinates server-side using ST_Y / ST_X.
///
/// Required Supabase SQL (run once in the SQL Editor):
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
///   longitude     double precision
/// )
/// LANGUAGE sql
/// SECURITY DEFINER
/// AS $$
///   SELECT
///     id,
///     name,
///     radius_meters,
///     leader_id,
///     description,
///     created_at,
///     ST_Y(location::geometry) AS latitude,
///     ST_X(location::geometry) AS longitude
///   FROM spots;
/// $$;
/// ```
class SpotRepository {
  SpotRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches all spots with extracted lat/lng coordinates.
  Future<List<Spot>> fetchSpots() async {
    final response = await _client.rpc('get_spots_with_coords');
    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Spot.fromJson)
        .toList();
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
  ///   longitude     double precision
  /// )
  /// LANGUAGE sql
  /// SECURITY DEFINER
  /// AS $$
  ///   SELECT
  ///     id, name, radius_meters, leader_id, description, created_at,
  ///     ST_Y(location::geometry) AS latitude,
  ///     ST_X(location::geometry) AS longitude
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
    int radiusMeters = 5000,
  }) async {
    final response = await _client.rpc('get_nearby_spots', params: {
      'lat': latitude,
      'lng': longitude,
      'radius_m': radiusMeters,
    });
    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Spot.fromJson)
        .toList();
  }
}
