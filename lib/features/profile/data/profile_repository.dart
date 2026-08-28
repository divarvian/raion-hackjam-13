import 'dart:io';
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

  /// Update the user's full name
  Future<void> updateProfileName(String newName) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    try {
      await _client
          .from(SupabaseConstants.tableProfiles)
          .update({'full_name': newName})
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Gagal memperbarui nama: $e');
    }
  }

  /// Upload new avatar and update profile
  Future<void> updateAvatar(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    try {
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '${user.id}/$fileName';

      await _client.storage.from('avatars').upload(path, imageFile);
      
      final imageUrl = _client.storage.from('avatars').getPublicUrl(path);

      await _client
          .from(SupabaseConstants.tableProfiles)
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Gagal mengunggah foto profil: $e');
    }
  }
}
