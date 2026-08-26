import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class VoteRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Call RPC to cast a vote (support or reject)
  Future<Map<String, dynamic>> castVote({
    required String policyId,
    required String voteType, // 'support' or 'reject'
  }) async {
    try {
      final response = await _client.rpc('cast_vote', params: {
        'p_policy_id': policyId,
        'p_vote_type': voteType,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Gagal melakukan vote: $e');
    }
  }
}
