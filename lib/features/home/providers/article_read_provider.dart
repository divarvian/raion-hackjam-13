import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../leaderboard/providers/leaderboard_provider.dart';
import '../../profile/providers/profile_provider.dart';
import 'policy_provider.dart';

/// Provider untuk mengelola state anti-farming pada artikel.
/// Logika: Harus stay > 30 detik DAN scroll mentok bawah untuk dapat +10 XP.
class ArticleReadNotifier extends AutoDisposeFamilyAsyncNotifier<bool, String> {
  Timer? _timer;
  int _secondsPassed = 0;
  bool _hasReachedBottom = false;
  bool _xpAwarded = false;

  @override
  FutureOr<bool> build(String arg) {
    // Start timer saat pertama kali dibuka
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsPassed++;
      _checkConditions();
    });
    
    // Cleanup timer saat screen ditutup (provider di-dispose)
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    return false; // false = belum dapat XP
  }

  /// Dipanggil dari ScrollController ketika user mentok bawah
  void setReachedBottom() {
    if (!_hasReachedBottom) {
      _hasReachedBottom = true;
      _checkConditions();
    }
  }

  void _checkConditions() async {
    if (_xpAwarded) return;
    
    // Syarat: min 30 detik & sudah scroll ke bawah
    if (_secondsPassed >= 30 && _hasReachedBottom) {
      _xpAwarded = true;
      
      // Hit RPC Supabase
      try {
        final repo = ref.read(policyRepositoryProvider);
        final result = await repo.completeArticleRead(
          policyId: arg,
          timeSpentSeconds: _secondsPassed,
        );
        
        if (result['success'] == true) {
          // Invalidate to update statistics
          ref.invalidate(userProfileProvider);
          ref.invalidate(topUsersProvider);
          
          state = const AsyncValue.data(true); // true = XP berhasil di-award
        }
      } catch (e) {
        // Abaikan error di UI jika gagal (misal koneksi mati)
        debugPrint('Gagal award XP: $e');
      }
    }
  }
}

final articleReadProvider = AutoDisposeAsyncNotifierProviderFamily<
    ArticleReadNotifier, bool, String>(
  () => ArticleReadNotifier(),
);
