/// Represents a 界隈ノート content item linked to a spot.
class Content {
  final String id;
  final String spotId;
  final String authorId;
  final String title;
  final Map<String, dynamic>? bodyJson;
  final bool isPremium;
  final int price;

  const Content({
    required this.id,
    required this.spotId,
    required this.authorId,
    required this.title,
    this.bodyJson,
    required this.isPremium,
    required this.price,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] as String,
      spotId: json['spot_id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      bodyJson: json['body_json'] as Map<String, dynamic>?,
      isPremium: (json['is_premium'] as bool?) ?? false,
      price: (json['price'] as num?)?.toInt() ?? 0,
    );
  }
}
