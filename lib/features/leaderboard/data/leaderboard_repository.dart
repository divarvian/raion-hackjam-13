import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';

class LeaderboardRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Fetch top users based on weekly_xp
  Future<List<Map<String, dynamic>>> getTopUsers({int limit = 10}) async {
    try {
      final response = await _client
          .from(SupabaseConstants.tableProfiles)
          .select('id, username, full_name, avatar_url, level, weekly_xp')
          .order('weekly_xp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal mengambil leaderboard: $e');
    }
  }
}
