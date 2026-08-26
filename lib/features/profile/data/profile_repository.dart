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
}
