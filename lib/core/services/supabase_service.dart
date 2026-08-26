import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton access ke Supabase client
///
/// Usage:
/// ```dart
/// final supabase = SupabaseService.client;
/// final user = supabase.auth.currentUser;
/// ```
class SupabaseService {
  SupabaseService._();

  /// Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user (null jika belum login)
  static User? get currentUser => client.auth.currentUser;

  /// Current user ID (throws jika belum login)
  static String get currentUserId {
    final user = currentUser;
    if (user == null) throw Exception('User belum login');
    return user.id;
  }

  /// Check apakah user sudah login
  static bool get isAuthenticated => currentUser != null;

  /// Stream perubahan auth state
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Inisialisasi Supabase — panggil di main.dart
  static Future<void> initialize({
    required String url,
    required String publishableKey,
  }) async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
    );
  }
}
