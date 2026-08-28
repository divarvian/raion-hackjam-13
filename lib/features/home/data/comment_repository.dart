import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class CommentRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> fetchComments(String policyId) async {
    final response = await _client
        .from('comments')
        .select('*, profiles(full_name, avatar_url)')
        .eq('policy_id', policyId)
        .order('created_at', ascending: true); // Ascending agar komentar lama di atas, reply berurutan
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchUserLikes(String policyId) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('comment_likes')
        .select('comment_id, comments!inner(policy_id)')
        .eq('user_id', user.id)
        .eq('comments.policy_id', policyId);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addComment({
    required String policyId,
    required String content,
    String? parentId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu');

    await _client.from('comments').insert({
      'user_id': user.id,
      'policy_id': policyId,
      'content': content,
      'parent_id': parentId,
    });
  }

  Future<void> toggleLike(String commentId, bool isCurrentlyLiked) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu');

    if (isCurrentlyLiked) {
      await _client
          .from('comment_likes')
          .delete()
          .eq('user_id', user.id)
          .eq('comment_id', commentId);
    } else {
      await _client
          .from('comment_likes')
          .insert({
        'user_id': user.id,
        'comment_id': commentId,
      });
    }
  }
}
