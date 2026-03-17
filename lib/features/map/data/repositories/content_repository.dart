import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/content.dart';
import '../../domain/models/leaderboard_entry.dart';

/// Fetches 界隈ノート contents and leaderboard data from Supabase.
///
/// Required RPC — run once in Supabase SQL editor:
/// ```sql
/// create or replace function get_spot_leaderboard(p_spot_id uuid)
/// returns table (
///   user_id       uuid,
///   username      text,
///   avatar_url    text,
///   check_in_count bigint
/// )
/// language sql stable as $$
///   select
///     p.id        as user_id,
///     p.username,
///     p.avatar_url,
///     count(c.id) as check_in_count
///   from check_ins c
///   join profiles  p on p.id = c.user_id
///   where c.spot_id = p_spot_id
///   group by p.id, p.username, p.avatar_url
///   order by check_in_count desc;
/// $$;
/// ```
class ContentRepository {
  final _client = Supabase.instance.client;

  /// Fetches all content items for the given [spotId], ordered newest first.
  Future<List<Content>> fetchContents(String spotId) async {
    final response = await _client
        .from('contents')
        .select()
        .eq('spot_id', spotId)
        .order('title');

    return (response as List)
        .map((row) => Content.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Returns ranked check-in counts for the given [spotId] via RPC.
  Future<List<LeaderboardEntry>> getLeaderboard(String spotId) async {
    final response = await _client
        .rpc('get_spot_leaderboard', params: {'p_spot_id': spotId});

    // Supabase may return null instead of [] when the RPC produces 0 rows.
    if (response == null) return const [];

    return (response as List)
        .map((row) => LeaderboardEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a new public note into the [contents] table for [spotId].
  Future<Content> createContent({
    required String spotId,
    required String authorId,
    required String title,
    required String body,
  }) async {
    debugPrint(
      '[ContentRepository] createContent → spotId=$spotId authorId=$authorId',
    );
    try {
      final response = await _client
          .from('contents')
          .insert({
            'spot_id': spotId,
            'author_id': authorId,
            'title': title,
            'body_json': {'text': body},
            'is_premium': false,
            'price': 0,
          })
          .select()
          .single();
      debugPrint('[ContentRepository] createContent ✓ id=${response['id']}');
      return Content.fromJson(response);
    } catch (e) {
      debugPrint('[ContentRepository] createContent ✗ ${e.toString()}');
      rethrow;
    }
  }

  /// Real-time stream of leaderboard entries for [spotId].
  ///
  /// Always emits an initial snapshot immediately so the UI never hangs on
  /// a loading spinner when there are zero check-ins (Supabase's `.stream()`
  /// may not emit at all when the filtered result set is empty).
  ///
  /// Subsequent emissions are triggered by realtime changes to `check_ins`.
  Stream<List<LeaderboardEntry>> leaderboardStream(String spotId) async* {
    // Always emit an initial snapshot. Swallow any error so the stream never
    // terminates before emitting — a null/error response becomes an empty list.
    try {
      yield await getLeaderboard(spotId);
    } catch (e) {
      debugPrint('[ContentRepository] leaderboardStream initial fetch error: $e');
      yield const [];
    }

    // Continue forwarding realtime check-in events; swallow per-event errors
    // to avoid breaking the stream on transient failures.
    await for (final _ in _client
        .from('check_ins')
        .stream(primaryKey: ['id'])
        .eq('spot_id', spotId)) {
      try {
        yield await getLeaderboard(spotId);
      } catch (_) {
        // Keep last known state; don't re-emit on error.
      }
    }
  }
}
