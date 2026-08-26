import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/policy_repository.dart';
import '../domain/policy_model.dart';

/// Provider untuk instance PolicyRepository
final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return PolicyRepository();
});

/// Provider untuk Top Trending Policy (Hero Card)
final topTrendingPolicyProvider = FutureProvider.autoDispose<PolicyModel?>((ref) async {
  final repo = ref.watch(policyRepositoryProvider);
  return repo.getTopTrendingPolicy();
});

/// Provider untuk Recent Policies List
final recentPoliciesProvider = FutureProvider.autoDispose<List<PolicyModel>>((ref) async {
  final repo = ref.watch(policyRepositoryProvider);
  return repo.getRecentPolicies(limit: 5);
});

/// Provider untuk detail policy berdasarkan ID
final policyDetailProvider = FutureProvider.autoDispose.family<PolicyModel, String>((ref, id) async {
  final repo = ref.watch(policyRepositoryProvider);
  return repo.getPolicyById(id);
});
