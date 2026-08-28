import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';

class LeaderboardRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Fetch top users based on period
  Future<List<Map<String, dynamic>>> getTopUsers({int limit = 10, String period = 'weekly'}) async {
    try {
      String orderBy = 'weekly_xp';
      if (period == 'monthly') orderBy = 'monthly_xp';
      if (period == 'all') orderBy = 'total_xp';

      final response = await _client
          .from(SupabaseConstants.tableProfiles)
          .select('id, username, full_name, avatar_url, level, weekly_xp, monthly_xp, total_xp')
          .order(orderBy, ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal mengambil leaderboard: $e');
    }
  }

  /// Get specific user's rank and total users for a period
  Future<Map<String, dynamic>> getUserRank(String period) async {
    try {
      final response = await _client.rpc('get_user_rank', params: {
        'p_period': period,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Gagal mengambil peringkat: $e');
    }
  }
}
