/// Represents a single check-in event recorded in Supabase.
class CheckIn {
  final String id;
  final String userId;
  final String spotId;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final String? status;

  const CheckIn({
    required this.id,
    required this.userId,
    required this.spotId,
    required this.checkInAt,
    this.checkOutAt,
    this.status,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        spotId: json['spot_id'] as String,
        checkInAt: DateTime.parse(json['check_in_at'] as String),
        checkOutAt: json['check_out_at'] != null
            ? DateTime.parse(json['check_out_at'] as String)
            : null,
        status: json['status'] as String?,
      );
}
