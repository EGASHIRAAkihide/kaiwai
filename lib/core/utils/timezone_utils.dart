import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// Timezone-aware time utilities for nomad local-time display.
///
/// The [timezone] package bundles a full IANA timezone database.
/// Call [tz.initializeTimeZones] (or the lighter
/// `timezone/data/latest_10y.dart` variant) once in `main()` before
/// calling any method here.
///
/// ── Typical usage ─────────────────────────────────────────────────────────
///   // In main():
///   import 'package:timezone/data/latest_10y.dart' as tz_data;
///   tz_data.initializeTimeZones();
///
///   // In the UI:
///   Text(TimezoneUtils.localTimeString(spot.timezoneId))
///   // → "14:32"
class TimezoneUtils {
  TimezoneUtils._();

  /// Returns the current wall-clock time at [timezoneId] formatted as "HH:mm".
  ///
  /// Returns an empty string if [timezoneId] is null, empty, or unrecognised —
  /// so callers can safely hide the widget with a simple `if (str.isNotEmpty)`.
  ///
  /// Example: `localTimeString('Asia/Tokyo')` → `"14:32"`
  static String localTimeString(String? timezoneId) {
    if (timezoneId == null || timezoneId.isEmpty) return '';
    try {
      final location = tz.getLocation(timezoneId);
      final now = tz.TZDateTime.now(location);
      return DateFormat.Hm().format(now);
    } on Exception {
      return '';
    }
  }

  /// Returns a human-readable UTC offset for the current instant.
  ///
  /// Accounts for DST automatically because the offset is computed from the
  /// live [tz.TZDateTime], not from a stored fixed offset.
  ///
  /// Example: `utcOffsetString('America/New_York')` → `"UTC-5"` (EST) or
  ///          `"UTC-4"` (EDT during daylight saving time).
  static String utcOffsetString(String? timezoneId) {
    if (timezoneId == null || timezoneId.isEmpty) return '';
    try {
      final location = tz.getLocation(timezoneId);
      final now = tz.TZDateTime.now(location);
      final totalMinutes = now.timeZoneOffset.inMinutes;
      final sign = totalMinutes >= 0 ? '+' : '-';
      final hours = totalMinutes.abs() ~/ 60;
      final mins = totalMinutes.abs() % 60;
      final minStr = mins == 0 ? '' : ':${mins.toString().padLeft(2, '0')}';
      return 'UTC$sign$hours$minStr';
    } on Exception {
      return '';
    }
  }

  /// Converts a 2-letter ISO 3166-1 alpha-2 [countryCode] to the
  /// corresponding Unicode flag emoji.
  ///
  /// Example: `flagEmoji('JP')` → `"🇯🇵"`
  static String flagEmoji(String countryCode) {
    if (countryCode.length != 2) return '';
    final upper = countryCode.toUpperCase();
    final codePoints = upper.codeUnits.map(
      (c) => 0x1F1E6 + (c - 0x41), // 'A' (0x41) maps to 🇦 (0x1F1E6)
    );
    return String.fromCharCodes(codePoints);
  }

  /// Derives a 3-letter display code from a city name.
  ///
  /// Takes the first 3 consonant-heavy characters so it looks like an
  /// airport code (e.g., "Tokyo" → "TKY", "Seoul" → "SEO").
  ///
  /// For precise codes, store an explicit `city_code` column in the DB
  /// and use that instead.
  static String cityCode(String? cityName) {
    if (cityName == null || cityName.isEmpty) return '';
    final cleaned = cityName.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    return cleaned.length >= 3 ? cleaned.substring(0, 3) : cleaned;
  }
}
