import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/flashcard_repository.dart';
import '../domain/flashcard_category_model.dart';
import '../domain/flashcard_topic_model.dart';
import '../domain/flashcard_model.dart';
import '../domain/user_flashcard_progress_model.dart';

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepository();
});

final flashcardCategoriesProvider = FutureProvider.autoDispose<List<FlashcardCategory>>((ref) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getCategories();
});

final flashcardTopicsProvider = FutureProvider.autoDispose.family<List<FlashcardTopic>, String>((ref, categoryId) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getTopicsByCategory(categoryId);
});

final allFlashcardTopicsProvider = FutureProvider.autoDispose<List<FlashcardTopic>>((ref) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getAllTopics();
});

final flashcardsProvider = FutureProvider.autoDispose.family<List<Flashcard>, String>((ref, topicId) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getFlashcardsByTopic(topicId);
});

final userFlashcardProgressProvider = FutureProvider.autoDispose.family<UserFlashcardProgress?, String>((ref, topicId) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getUserProgress(topicId);
});

// A notifier to manage active flashcard session
class FlashcardSessionState {
  final int currentIndex;
  final bool isCompleted;
  
  FlashcardSessionState({
    required this.currentIndex,
    required this.isCompleted,
  });
  
  FlashcardSessionState copyWith({
    int? currentIndex,
    bool? isCompleted,
  }) {
    return FlashcardSessionState(
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class FlashcardSessionNotifier extends AutoDisposeFamilyNotifier<FlashcardSessionState, String> {
  int? _localIndex;
  bool? _localCompleted;

  @override
  FlashcardSessionState build(String arg) {
    final progressAsync = ref.watch(userFlashcardProgressProvider(arg));
    return FlashcardSessionState(
      currentIndex: _localIndex ?? progressAsync.valueOrNull?.lastCardIndex ?? 0,
      isCompleted: _localCompleted ?? progressAsync.valueOrNull?.isCompleted ?? false,
    );
  }

  Future<void> updateProgress({
    required int currentIndex,
    required bool isCompleted,
    required int totalCards,
    required int xpReward,
  }) async {
    _localIndex = currentIndex;
    _localCompleted = isCompleted;
    state = state.copyWith(currentIndex: currentIndex, isCompleted: isCompleted);
    
    final repo = ref.read(flashcardRepositoryProvider);
    final previousProgress = await repo.getUserProgress(arg);
    
    await repo.saveProgress(
      topicId: arg,
      cardsCompleted: currentIndex,
      isCompleted: isCompleted,
      lastCardIndex: currentIndex,
    );
    
    // Award XP if completed for the first time
    if (isCompleted && (previousProgress == null || !previousProgress.xpAwarded)) {
      await repo.awardTopicXp(arg, xpReward);
      ref.invalidate(userFlashcardProgressProvider(arg));
      ref.invalidate(userProfileProvider);
    }
  }
}

final flashcardSessionProvider = AutoDisposeNotifierProviderFamily<FlashcardSessionNotifier, FlashcardSessionState, String>(() {
  return FlashcardSessionNotifier();
});
