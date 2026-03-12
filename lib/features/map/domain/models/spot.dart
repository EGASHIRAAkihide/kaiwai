import 'package:latlong2/latlong.dart';

/// Represents a KAIWAI spot (界隈) — a community training location.
///
/// ── Coordinate sourcing ──────────────────────────────────────────────────
/// The [latitude] and [longitude] fields are extracted from the PostGIS
/// `geography(POINT)` column server-side. See [SpotRepository] for the
/// required Supabase RPC.
///
/// ── Global-ready fields ──────────────────────────────────────────────────
/// [cityName], [countryCode], and [timezoneId] support international nomad
/// use and are all optional so existing spots without these columns continue
/// to parse correctly.
///
/// Required DB migration (run once):
/// ```sql
/// ALTER TABLE spots ADD COLUMN IF NOT EXISTS city_name    text;
/// ALTER TABLE spots ADD COLUMN IF NOT EXISTS country_code char(2);
/// ALTER TABLE spots ADD COLUMN IF NOT EXISTS timezone_id  text;
/// ```
/// Update the `get_spots_with_coords` and `get_nearby_spots` RPCs to
/// SELECT these three new columns alongside the existing ones.
class Spot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String? leaderId;
  final String? description;
  final DateTime? createdAt;

  // ── Global metadata ─────────────────────────────────────────────────────

  /// Human-readable city name, e.g. "Tokyo" or "Seoul".
  ///
  /// Used to derive a 3-letter display code for the Global Badge in
  /// [SpotDetailScreen] via [TimezoneUtils.cityCode].
  final String? cityName;

  /// ISO 3166-1 alpha-2 country code, e.g. "JP", "KR", "NP".
  ///
  /// Converted to a flag emoji via [TimezoneUtils.flagEmoji].
  final String? countryCode;

  /// IANA timezone database identifier, e.g. "Asia/Tokyo".
  ///
  /// Pass to [TimezoneUtils.localTimeString] to display the spot's current
  /// local time regardless of the user's device timezone — critical for
  /// international nomads travelling across multiple time zones.
  final String? timezoneId;

  const Spot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.leaderId,
    this.description,
    this.createdAt,
    this.cityName,
    this.countryCode,
    this.timezoneId,
  });

  /// Convenience getter for use with flutter_map.
  LatLng get latLng => LatLng(latitude, longitude);

  factory Spot.fromJson(Map<String, dynamic> json) {
    // Support both 'latitude'/'longitude' and 'lat'/'lng' key variants
    final lat = (json['latitude'] ?? json['lat']) as num?;
    final lng = (json['longitude'] ?? json['lng']) as num?;
    if (lat == null || lng == null) {
      throw FormatException(
        'Spot.fromJson: missing lat/lng. Keys present: ${json.keys.toList()}',
      );
    }
    final createdAtRaw = json['created_at'] as String?;
    return Spot(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toInt() ?? 0,
      leaderId: json['leader_id'] as String?,
      description: json['description'] as String?,
      createdAt: createdAtRaw != null ? DateTime.parse(createdAtRaw) : null,
      // Global metadata — gracefully absent on older rows
      cityName: json['city_name'] as String?,
      countryCode: json['country_code'] as String?,
      timezoneId: json['timezone_id'] as String?,
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
        'created_at': createdAt?.toIso8601String(),
        'city_name': cityName,
        'country_code': countryCode,
        'timezone_id': timezoneId,
      };

  @override
  bool operator ==(Object other) => other is Spot && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
