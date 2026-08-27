import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../domain/flashcard_model.dart';
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

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Survival Guide', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: flashcardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('Tidak ada kartu di topik ini.'));
          }

          // If session is completed or all cards are swiped
          if (sessionState.isCompleted || sessionState.currentIndex >= cards.length) {
            return _buildCompletionScreen(context);
          }

          return SafeArea(
            child: Column(
              children: [
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (sessionState.currentIndex) / cards.length,
                          backgroundColor: AppColors.divider,
                          color: AppColors.primary,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${sessionState.currentIndex}/${cards.length}',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                
                // Swiper
                Expanded(
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: cards.length,
                    initialIndex: ref.read(flashcardSessionProvider(widget.topicId)).currentIndex,
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
                      return _buildCard(cards[index], index);
                    },
                  ),
                ),
                
                // Hints
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p32),
                  child: Builder(
                    builder: (context) {
                      final topCardIndex = ref.read(flashcardSessionProvider(widget.topicId)).currentIndex;
                      final isTopCardQuiz = topCardIndex < cards.length && cards[topCardIndex].cardType == 'question';
                      final isUnanswered = isTopCardQuiz && !_answeredCardIndices.contains(topCardIndex);
                      
                      return Text(
                        isUnanswered ? 'Pilih salah satu jawaban di atas' : 'Geser ke kiri atau kanan untuk lanjut',
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

  Widget _buildCard(Flashcard card, int cardIndex) {
    Color badgeColor = AppColors.primary;
    String badgeText = 'Info';
    
    if (card.cardType == 'fun_fact') {
      badgeColor = Colors.orange;
      badgeText = 'Fun Fact 💡';
    } else if (card.cardType == 'question') {
      badgeColor = Colors.purple;
      badgeText = 'Kuis 🤔';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.r12),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.labelLarge.copyWith(color: badgeColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          if (card.title != null) ...[
            Text(
              card.title!,
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
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
          ]
        ],
      ),
    );
  }


  Widget _buildCompletionScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 100),
          const SizedBox(height: 24),
          Text(
            'Luar Biasa!',
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Kamu telah menyelesaikan topik ini\ndan mendapatkan XP!',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Selesai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
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
            bgColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green;
            trailingIcon = Icons.check_circle;
          } else if (isSelected) {
            bgColor = Colors.red.withValues(alpha: 0.1);
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
