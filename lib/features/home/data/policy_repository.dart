import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../domain/policy_model.dart';

class PolicyRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Fetch trending policy (untuk hero card di Beranda)
  Future<PolicyModel?> getTopTrendingPolicy() async {
    try {
      final response = await _client
          .from(SupabaseConstants.tablePolicies)
          .select('*, comments(count)')
          .eq('is_trending', true)
          .eq('is_published', true)
          .order('trending_rank', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return PolicyModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil trending policy: $e');
    }
  }

  /// Fetch recent policies (untuk list di Beranda)
  Future<List<PolicyModel>> getRecentPolicies({int limit = 10}) async {
    try {
      final response = await _client
          .from(SupabaseConstants.tablePolicies)
          .select('*, comments(count)')
          .eq('is_published', true)
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => PolicyModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar policy: $e');
    }
  }

  /// Fetch policies by categories (untuk For You tab)
  Future<List<PolicyModel>> getPoliciesByCategories(List<String> categories, {int limit = 10}) async {
    if (categories.isEmpty) return getRecentPolicies(limit: limit);
    
    try {
      final response = await _client
          .from(SupabaseConstants.tablePolicies)
          .select('*, comments(count)')
          .eq('is_published', true)
          .inFilter('category', categories)
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => PolicyModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar policy berdasar minat: $e');
    }
  }

  /// Fetch detail policy by ID
  Future<PolicyModel> getPolicyById(String id) async {
    try {
      final response = await _client
          .from(SupabaseConstants.tablePolicies)
          .select('*, comments(count)')
          .eq('id', id)
          .single();

      return PolicyModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil detail policy: $e');
    }
  }

  /// Check if user has already read and received XP for this article
  Future<bool> hasReadArticle(String policyId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      final res = await _client
          .from('article_reads')
          .select('xp_awarded')
          .eq('user_id', user.id)
          .eq('policy_id', policyId)
          .maybeSingle();
      if (res != null) {
        return res['xp_awarded'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Call RPC to award XP after reading article
  Future<Map<String, dynamic>> completeArticleRead({
    required String policyId,
    required int timeSpentSeconds,
  }) async {
    try {
      final response = await _client.rpc('complete_article_read', params: {
        'p_policy_id': policyId,
        'p_time_spent': timeSpentSeconds,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Gagal memberikan XP: $e');
    }
  }
}
