import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/providers/profile_provider.dart';

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

/// Provider untuk For You Policies List
final forYouPoliciesProvider = FutureProvider.autoDispose<List<PolicyModel>>((ref) async {
  final repo = ref.watch(policyRepositoryProvider);
  
  try {
    final userProfile = await ref.watch(userProfileProvider.future);
    final interestedTopics = (userProfile['interested_topics'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return repo.getPoliciesByCategories(interestedTopics, limit: 10);
  } catch (e) {
    // Fallback to recent policies if profile fetch fails
    return repo.getRecentPolicies(limit: 10);
  }
});

/// Provider untuk detail policy berdasarkan ID
final policyDetailProvider = FutureProvider.autoDispose.family<PolicyModel, String>((ref, id) async {
  final repo = ref.watch(policyRepositoryProvider);
  return repo.getPolicyById(id);
});
