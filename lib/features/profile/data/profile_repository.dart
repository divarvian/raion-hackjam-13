import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';

class ProfileRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Fetch user profile based on current logged in user
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    try {
      final response = await _client
          .from(SupabaseConstants.tableProfiles)
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Gagal mengambil profil: $e');
    }
  }

  /// Update interested topics for the current user
  Future<void> updateInterestedTopics(List<String> topics) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    try {
      await _client
          .from(SupabaseConstants.tableProfiles)
          .update({'interested_topics': topics})
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Gagal menyimpan preferensi topik: $e');
    }
  }
}
