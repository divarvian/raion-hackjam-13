import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../leaderboard/providers/leaderboard_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/vote_repository.dart';

final voteRepositoryProvider = Provider<VoteRepository>((ref) {
  return VoteRepository();
});

class VoteNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final VoteRepository _repository;
  final Ref _ref;

  VoteNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> castVote({
    required String policyId,
    required String voteType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.castVote(
        policyId: policyId,
        voteType: voteType,
      );
      
      // Invalidate to update statistics
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(topUsersProvider);
      
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final voteProvider = StateNotifierProvider<VoteNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final repo = ref.watch(voteRepositoryProvider);
  return VoteNotifier(repo, ref);
});
