import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getCurrentUserProfile();
});
