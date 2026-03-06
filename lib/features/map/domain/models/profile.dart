/// Represents a KAIWAI user profile.
/// See: docs/db/schema.md → profiles table.
class Profile {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final bool isLeader;

  const Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.isLeader,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      isLeader: json['is_leader'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'bio': bio,
        'is_leader': isLeader,
      };

  @override
  bool operator ==(Object other) => other is Profile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
