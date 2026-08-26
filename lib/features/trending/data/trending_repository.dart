import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../../home/domain/policy_model.dart';

class TrendingRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Mengambil daftar isu trending berdasarkan total_votes terbanyak
  Future<List<PolicyModel>> getTrendingPolicies({int limit = 10}) async {
    try {
      final response = await _client
          .from(SupabaseConstants.tablePolicies)
          .select()
          .eq('is_published', true)
          .order('total_votes', ascending: false) // Urutkan dari vote terbanyak
          .limit(limit);

      return (response as List).map((json) => PolicyModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data trending: $e');
    }
  }
}
