import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../leaderboard/providers/leaderboard_provider.dart';
import '../../profile/providers/profile_provider.dart';
import 'policy_provider.dart';

class ArticleReadState {
  final int secondsPassed;
  final bool hasReachedBottom;
  final bool xpAwarded;

  ArticleReadState({
    required this.secondsPassed,
    required this.hasReachedBottom,
    required this.xpAwarded,
  });
}

/// Provider untuk mengelola state anti-farming pada artikel.
/// Logika: Harus stay > 30 detik DAN scroll mentok bawah untuk dapat +10 XP.
class ArticleReadNotifier extends AutoDisposeFamilyAsyncNotifier<ArticleReadState, String> {
  Timer? _timer;
  int _secondsPassed = 0;
  bool _hasReachedBottom = false;
  bool _xpAwarded = false;

  @override
  FutureOr<ArticleReadState> build(String arg) async {
    final repo = ref.read(policyRepositoryProvider);
    _xpAwarded = await repo.hasReadArticle(arg);
    
    if (!_xpAwarded) {
      // Start timer saat pertama kali dibuka HANYA JIKA belum dapat XP
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _secondsPassed++;
        _updateState();
        _checkConditions();
      });
    }
    
    // Cleanup timer saat screen ditutup (provider di-dispose)
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    return _buildCurrentState();
  }

  ArticleReadState _buildCurrentState() {
    return ArticleReadState(
      secondsPassed: _secondsPassed,
      hasReachedBottom: _hasReachedBottom,
      xpAwarded: _xpAwarded,
    );
  }

  void _updateState() {
    state = AsyncValue.data(_buildCurrentState());
  }

  /// Dipanggil dari ScrollController ketika user mentok bawah
  void setReachedBottom() {
    if (!_hasReachedBottom) {
      _hasReachedBottom = true;
      _updateState();
      _checkConditions();
    }
  }

  void _checkConditions() async {
    if (_xpAwarded) return;
    
    // Syarat: min 30 detik & sudah scroll ke bawah
    if (_secondsPassed >= 30 && _hasReachedBottom) {
      // Hit RPC Supabase
      try {
        final repo = ref.read(policyRepositoryProvider);
        final result = await repo.completeArticleRead(
          policyId: arg,
          timeSpentSeconds: _secondsPassed,
        );
        
        if (result['success'] == true) {
          _xpAwarded = true; // Set local state only if backend success
          // Invalidate to update statistics
          ref.invalidate(userProfileProvider);
          ref.invalidate(topUsersProvider);
          
          _updateState();
        } else {
           // Jika backend menolak (misal sudah pernah), stop _xpAwarded agar tidak terus dipanggil
           _xpAwarded = true; 
           _updateState();
        }
      } catch (e) {
        // Abaikan error di UI jika gagal (misal koneksi mati)
        debugPrint('Gagal award XP: $e');
      }
    }
  }
}

final articleReadProvider = AutoDisposeAsyncNotifierProviderFamily<
    ArticleReadNotifier, ArticleReadState, String>(
  () => ArticleReadNotifier(),
);
