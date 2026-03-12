/// A single row returned by the `get_spot_leaderboard` RPC.
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int checkInCount;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.checkInCount,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      checkInCount: (json['check_in_count'] as num).toInt(),
    );
  }
}
