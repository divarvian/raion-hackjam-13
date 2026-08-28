import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/leaderboard_repository.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

// State for selected period: 'weekly', 'monthly', 'all'
final leaderboardPeriodProvider = StateProvider<String>((ref) => 'weekly');

final topUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final period = ref.watch(leaderboardPeriodProvider);
  return repo.getTopUsers(limit: 10, period: period);
});

final userRankProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final period = ref.watch(leaderboardPeriodProvider);
  return repo.getUserRank(period);
});
