import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/check_in.dart';

/// Handles check-in writes to the Supabase `check_ins` table.
class CheckInRepository {
  CheckInRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Inserts a new check-in record and returns the created [CheckIn].
  Future<CheckIn> checkIn({
    required String spotId,
    required String userId,
    String? status,
  }) async {
    final response = await _client
        .from('check_ins')
        .insert({
          'spot_id': spotId,
          'user_id': userId,
          'check_in_at': DateTime.now().toUtc().toIso8601String(),
          if (status != null) 'status': status,
        })
        .select()
        .single();
    return CheckIn.fromJson(response);
  }
}
