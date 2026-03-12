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

    return (response as List)
        .map((row) => LeaderboardEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
