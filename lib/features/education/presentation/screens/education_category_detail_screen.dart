import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/flashcard_topic_model.dart';
import '../../providers/flashcard_provider.dart';

class EducationCategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const EducationCategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(flashcardTopicsProvider(categoryId));
    final categoriesAsync = ref.watch(flashcardCategoriesProvider);
    
    // Find category info for header
    final category = categoriesAsync.valueOrNull?.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw Exception('Kategori tidak ditemukan'),
    );

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edukasi',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: topicsAsync.when(
        data: (topics) {
          if (topics.isEmpty) {
            return const Center(child: Text('Belum ada panduan di kategori ini.'));
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Category Detail
              if (category != null)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              category.name.substring(0, 1).toUpperCase(),
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: AppTextStyles.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${topics.length} panduan',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // The List
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.p24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final topic = topics[index];
                      return _buildTopicCard(context, ref, topic, index + 1);
                    },
                    childCount: topics.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24.0),
          child: AppShimmerList(itemCount: 5, itemHeight: 120),
        ),
        error: (err, stack) => AppErrorWidget(
          error: err,
          onRetry: () => ref.invalidate(flashcardTopicsProvider(categoryId)),
        ),
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, WidgetRef ref, FlashcardTopic topic, int number) {
    final progressAsync = ref.watch(userFlashcardProgressProvider(topic.id));
    
    final bool isCompleted = progressAsync.maybeWhen(
      data: (prog) => prog?.isCompleted ?? false,
      orElse: () => false,
    );

    String numberString = number.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            context.pushNamed(RouteNames.flashcardViewer, pathParameters: {'topicId': topic.id});
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Number / Check
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.withOpacity(0.1) : AppColors.divider.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.green, size: 24)
                        : Text(
                            numberString,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              topic.title,
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (topic.subtitle != null) ...[
                        Text(
                          topic.subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Text(
                            '${topic.totalCards} kartu • ±${topic.readTimeMinutes} mnt',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 12, color: Colors.green),
                                  const SizedBox(width: 2),
                                  Text(
                                    '+${topic.xpReward} XP',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
