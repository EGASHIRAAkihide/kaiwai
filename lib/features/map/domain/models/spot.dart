import 'package:latlong2/latlong.dart';

/// Represents a KAIWAI spot (界隈) — a community training location.
///
/// The [latitude] and [longitude] fields are extracted from the PostGIS
/// `geography(POINT)` column via the Supabase RPC `get_spots_with_coords`.
/// See: docs/db/schema.md → spots table.
class Spot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String leaderId;
  final String? description;
  final DateTime createdAt;

  const Spot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.leaderId,
    this.description,
    required this.createdAt,
  });

  /// Convenience getter for use with flutter_map.
  LatLng get latLng => LatLng(latitude, longitude);

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num).toInt(),
      leaderId: json['leader_id'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'leader_id': leaderId,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) => other is Spot && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
