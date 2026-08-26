import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/flashcard_category_model.dart';
import '../../domain/flashcard_topic_model.dart';
import '../../providers/flashcard_provider.dart';

/// Education Screen — Flashcard Survival Guide
class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(flashcardCategoriesProvider);
    final allTopicsAsync = ref.watch(allFlashcardTopicsProvider);

    final hasGlobalError = categoriesAsync.hasError || allTopicsAsync.hasError;
    final globalError = categoriesAsync.error ?? allTopicsAsync.error;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Force refresh providers
            ref.invalidate(flashcardCategoriesProvider);
            ref.invalidate(allFlashcardTopicsProvider);
            try {
              await Future.wait([
                ref.read(flashcardCategoriesProvider.future),
                ref.read(allFlashcardTopicsProvider.future),
              ]);
            } catch (_) {}
          },
          child: hasGlobalError
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    child: AppErrorWidget(
                      error: globalError!,
                      onRetry: () {
                        ref.invalidate(flashcardCategoriesProvider);
                        ref.invalidate(allFlashcardTopicsProvider);
                      },
                    ),
                  ),
                ],
              )
            : LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              const SizedBox(height: AppSizes.p8),

              // Header
              Text('Edukasi', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '✨ Survival Guide',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.support,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              Text(
                'Belajar hal penting,\nuntuk adulting cerdas.',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih kategori yang ingin kamu pelajari hari ini.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSizes.p24),

              // Categories
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text('Belum ada kategori edukasi.');
                  }
                  return Column(
                    children: categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.p12),
                        child: _buildCategoryCard(
                          title: cat.name,
                          description: cat.description ?? '',
                          color: _parseColor(cat.colorHex),
                          icon: _getIconData(cat.iconName),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const AppShimmerList(itemCount: 2, itemHeight: 80),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              
              const SizedBox(height: AppSizes.p24),

              // Popular Topics
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('Topik Populer', style: AppTextStyles.titleLarge),
                ],
              ),
              const SizedBox(height: AppSizes.p12),

              allTopicsAsync.when(
                data: (topics) {
                  if (topics.isEmpty) {
                    return const Text('Belum ada topik.');
                  }
                  return Column(
                    children: topics.map((topic) {
                      return _buildTopicCard(context, ref, topic);
                    }).toList(),
                  );
                },
                loading: () => const AppShimmerList(itemCount: 3, itemHeight: 90),
                error: (err, stack) => const SizedBox.shrink(),
              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, WidgetRef ref, FlashcardTopic topic) {
    // Watch user progress to show completion checkmark
    final progressAsync = ref.watch(userFlashcardProgressProvider(topic.id));
    
    final bool isCompleted = progressAsync.maybeWhen(
      data: (prog) => prog?.isCompleted ?? false,
      orElse: () => false,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        child: InkWell(
          onTap: () {
            context.pushNamed(RouteNames.flashcardViewer, pathParameters: {'topicId': topic.id});
          },
          borderRadius: BorderRadius.circular(AppSizes.r12),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.r12),
              border: Border.all(color: isCompleted ? Colors.green.withValues(alpha: 0.5) : AppColors.divider),
            ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getIconData(topic.iconName), color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${topic.totalCards} kartu • +${topic.xpReward} XP', style: AppTextStyles.caption),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text('Selesai', style: AppTextStyles.caption.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'record_voice_over':
        return Icons.record_voice_over_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'article':
      default:
        return Icons.article_rounded;
    }
  }
}
