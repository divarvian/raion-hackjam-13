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
  bool _isUpdating = false;

  int? _pendingIndex;
  bool? _pendingCompleted;

  @override
  FlashcardSessionState build(String arg) {
    final progressAsync = ref.watch(userFlashcardProgressProvider(arg));
    final isDbCompleted = progressAsync.valueOrNull?.isCompleted ?? false;
    
    return FlashcardSessionState(
      currentIndex: _localIndex ?? (isDbCompleted ? 0 : (progressAsync.valueOrNull?.lastCardIndex ?? 0)),
      isCompleted: _localCompleted ?? false, // Only show completion screen if completed in this local session
    );
  }

  Future<void> updateProgress({
    required int currentIndex,
    required bool isCompleted,
    required int totalCards,
    required int xpReward,
  }) async {
    // 1. Update UI state immediately!
    _localIndex = currentIndex;
    _localCompleted = isCompleted;
    state = state.copyWith(currentIndex: currentIndex, isCompleted: isCompleted);

    // 2. Queue the DB update
    _pendingIndex = currentIndex;
    _pendingCompleted = isCompleted;

    if (_isUpdating) return;
    _isUpdating = true;
    
    try {
      while (_pendingIndex != null) {
        final idx = _pendingIndex!;
        final comp = _pendingCompleted!;
        _pendingIndex = null;
        _pendingCompleted = null;

        final repo = ref.read(flashcardRepositoryProvider);
        
        await repo.saveProgress(
          topicId: arg,
          cardsCompleted: idx,
          isCompleted: comp,
          lastCardIndex: idx,
        );

        final previousProgress = ref.read(userFlashcardProgressProvider(arg)).valueOrNull;

        // Award XP if completed for the first time
        if (comp && (previousProgress == null || !previousProgress.xpAwarded)) {
          await repo.awardTopicXp(arg, xpReward);
          ref.invalidate(userFlashcardProgressProvider(arg));
          ref.invalidate(userProfileProvider);
        }
      }
    } finally {
      _isUpdating = false;
    }
  }
}

final flashcardSessionProvider = AutoDisposeNotifierProviderFamily<FlashcardSessionNotifier, FlashcardSessionState, String>(() {
  return FlashcardSessionNotifier();
});
