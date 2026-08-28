import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../domain/flashcard_model.dart';
import '../../domain/flashcard_topic_model.dart';
import '../../providers/flashcard_provider.dart';

class FlashcardViewerScreen extends ConsumerStatefulWidget {
  final String topicId;

  const FlashcardViewerScreen({super.key, required this.topicId});

  @override
  ConsumerState<FlashcardViewerScreen> createState() => _FlashcardViewerScreenState();
}

class _FlashcardViewerScreenState extends ConsumerState<FlashcardViewerScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  late FlashcardSessionNotifier _sessionNotifier;
  final Set<int> _answeredCardIndices = {};

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashcardsAsync = ref.watch(flashcardsProvider(widget.topicId));
    final sessionState = ref.watch(flashcardSessionProvider(widget.topicId));
    _sessionNotifier = ref.read(flashcardSessionProvider(widget.topicId).notifier);
    
    // We fetch all topics to find the current topic info (for completion screen & category name)
    final allTopicsAsync = ref.watch(allFlashcardTopicsProvider);
    final categoriesAsync = ref.watch(flashcardCategoriesProvider);

    final topic = allTopicsAsync.valueOrNull?.firstWhere(
      (t) => t.id == widget.topicId,
      orElse: () => FlashcardTopic(
        id: widget.topicId, 
        categoryId: '', 
        title: '', 
        iconName: 'article', 
        totalCards: 0, 
        orderIndex: 0, 
        isLocked: false, 
        xpReward: 15,
        readTimeMinutes: 2,
        keyTakeaways: [],
      ),
    );

    final categoryName = categoriesAsync.valueOrNull?.firstWhere(
      (c) => c.id == topic?.categoryId,
      orElse: () => throw Exception(),
    ).name ?? 'Edukasi';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Lighter grey background per design
      body: flashcardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('Tidak ada kartu di topik ini.'));
          }

          // If session is completed or all cards are swiped
          if (sessionState.isCompleted || sessionState.currentIndex >= cards.length) {
            return _buildCompletionScreen(context, topic, categoryName);
          }

          return SafeArea(
            child: Column(
              children: [
                // Custom App Bar / Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.black87),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${(sessionState.currentIndex + 1).toString().padLeft(2, '0')}/${cards.length.toString().padLeft(2, '0')}',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(
                    value: (sessionState.currentIndex + 1) / cards.length,
                    backgroundColor: AppColors.divider,
                    color: AppColors.primary,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Swiper
                Expanded(
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: cards.length,
                    initialIndex: sessionState.currentIndex,
                    isLoop: false,
                    allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                    onSwipe: (previousIndex, currentIndex, direction) {
                      final swipedCard = cards[previousIndex];
                      if (swipedCard.cardType == 'question' && !_answeredCardIndices.contains(previousIndex)) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        SnackbarUtils.showWarning(context, 'Eits, jawab kuisnya dulu dong! 🤓');
                        return false;
                      }

                      if (currentIndex != null) {
                        _handleSwipe(cards.length, currentIndex);
                      } else {
                        // Swiped the last card
                        _handleEnd(cards.length);
                      }
                      return true;
                    },
                    onEnd: () {
                      _handleEnd(cards.length);
                    },
                    padding: const EdgeInsets.all(AppSizes.p24),
                    cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                      return _buildCard(cards[index], index, cards.length);
                    },
                  ),
                ),
                
                // Hints
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p32),
                  child: Builder(
                    builder: (context) {
                      final topCardIndex = sessionState.currentIndex;
                      final isTopCardQuiz = topCardIndex < cards.length && cards[topCardIndex].cardType == 'question';
                      final isUnanswered = isTopCardQuiz && !_answeredCardIndices.contains(topCardIndex);
                      
                      return Text(
                        isUnanswered ? 'Pilih salah satu jawaban di atas' : 'Swipe ke kiri untuk lanjut',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isUnanswered ? AppColors.warning : AppColors.textTertiary,
                          fontWeight: isUnanswered ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => AppErrorWidget(
          error: err,
          onRetry: () => ref.invalidate(flashcardsProvider(widget.topicId)),
        ),
      ),
    );
  }

  void _handleSwipe(int totalCards, int nextIndex) {
    _sessionNotifier.updateProgress(
      currentIndex: nextIndex,
      isCompleted: false,
      totalCards: totalCards,
      xpReward: 15,
    );
  }

  void _handleEnd(int totalCards) {
    _sessionNotifier.updateProgress(
      currentIndex: totalCards,
      isCompleted: true,
      totalCards: totalCards,
      xpReward: 15,
    );
  }

  Widget _buildCard(Flashcard card, int cardIndex, int totalCards) {
    Color badgeColor = AppColors.primary;
    Color badgeTextColor = AppColors.primary;
    String badgeText = 'INFO';
    
    // Default HOOK style (Reddish)
    if (card.cardType == 'hook' || card.cardType == 'info' || card.cardType == null || card.cardType!.isEmpty) {
      badgeColor = AppColors.primary.withOpacity(0.15);
      badgeTextColor = AppColors.primary;
      badgeText = card.cardType?.toUpperCase() ?? 'HOOK';
      if (badgeText == '') badgeText = 'HOOK';
    } else if (card.cardType == 'fun_fact') {
      badgeColor = Colors.orange.withOpacity(0.15);
      badgeTextColor = Colors.orange;
      badgeText = 'FUN FACT';
    } else if (card.cardType == 'question') {
      badgeColor = Colors.purple.withOpacity(0.15);
      badgeTextColor = Colors.purple;
      badgeText = 'KUIS';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(AppSizes.r12),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.labelMedium.copyWith(color: badgeTextColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          if (card.title != null) ...[
            Text(
              card.title!,
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p16),
          ],
          Text(
            card.contentText,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 18,
            ),
          ),
          if (card.extraContent != null && card.cardType == 'question') ...[
            const SizedBox(height: AppSizes.p24),
            _QuizCardContent(
              extraContent: card.extraContent!,
              onAnswered: () {
                setState(() {
                  _answeredCardIndices.add(cardIndex);
                });
              },
            ),
          ],
          
          const Spacer(),
          
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalCards, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == cardIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == cardIndex ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen(BuildContext context, FlashcardTopic? topic, String categoryName) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            // Main Icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33E52E2E), // Subtle red shadow
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, 10),
                  )
                ]
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            
            // XP Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // Soft orange/yellow
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 20), // Darker orange
                  const SizedBox(width: 4),
                  Text(
                    '+${topic?.xpReward ?? 15} XP Didapatkan!',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Text
            Text(
              'Guide Completed!',
              style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Adulting knowledge unlocked.\nKamu sekarang tahu apa yang bisa dilakukan.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Takeaways Box
            if (topic != null && topic.keyTakeaways.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YANG SUDAH KAMU PELAJARI',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 16),
                    ...topic.keyTakeaways.map((takeaway) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              takeaway,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              
            const Spacer(),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Jelajahi Guide Lain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Kembali ke root edukasi terlebih dahulu agar saat user membuka tab edukasi lagi, tidak tertahan di layar ini
                  context.go(RouteNames.education);
                  
                  // Baru kemudian pindah ke tab Home
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (context.mounted) {
                      context.go(RouteNames.home);
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Baca Isu Terkait', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCardContent extends StatefulWidget {
  final Map<String, dynamic> extraContent;
  final VoidCallback onAnswered;

  const _QuizCardContent({required this.extraContent, required this.onAnswered});

  @override
  State<_QuizCardContent> createState() => _QuizCardContentState();
}

class _QuizCardContentState extends State<_QuizCardContent> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> options = widget.extraContent['options'] ?? [];
    final int correctIndex = widget.extraContent['correct_index'] ?? 0;

    return Column(
      children: List.generate(options.length, (index) {
        final isSelected = _selectedIndex == index;
        final isCorrect = index == correctIndex;
        
        Color bgColor = Colors.transparent;
        Color borderColor = AppColors.divider;
        IconData? trailingIcon;
        
        if (_selectedIndex != null) {
          if (isCorrect) {
            bgColor = Colors.green.withOpacity(0.1);
            borderColor = Colors.green;
            trailingIcon = Icons.check_circle;
          } else if (isSelected) {
            bgColor = Colors.red.withOpacity(0.1);
            borderColor = Colors.red;
            trailingIcon = Icons.cancel;
          }
        }

        return GestureDetector(
          onTap: () {
            if (_selectedIndex == null) {
              setState(() {
                _selectedIndex = index;
              });
              widget.onAnswered();
            }
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(
                color: borderColor, 
                width: isSelected || (_selectedIndex != null && isCorrect) ? 2 : 1
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    options[index].toString(),
                    style: AppTextStyles.titleMedium.copyWith(
                       color: _selectedIndex != null && isCorrect ? Colors.green 
                            : isSelected ? Colors.red : AppColors.textPrimary
                    ),
                  ),
                ),
                if (_selectedIndex != null && trailingIcon != null)
                  Icon(trailingIcon, color: isCorrect ? Colors.green : Colors.red),
              ],
            ),
          ),
        );
      }),
    );
  }
}
