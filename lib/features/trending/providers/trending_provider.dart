import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/trending_repository.dart';
import '../../home/domain/policy_model.dart';

final trendingRepositoryProvider = Provider<TrendingRepository>((ref) {
  return TrendingRepository();
});

final trendingPoliciesProvider = FutureProvider.autoDispose<List<PolicyModel>>((ref) async {
  final repo = ref.watch(trendingRepositoryProvider);
  return repo.getTrendingPolicies(limit: 10);
});
