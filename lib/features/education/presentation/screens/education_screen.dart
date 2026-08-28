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
      body: RefreshIndicator(
        onRefresh: () async {
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
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header Red Gradient
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE52E2E), // Darker red
                            AppColors.primary, // Red
                          ],
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 24,
                        left: 24,
                        right: 24,
                        bottom: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EDUKASI',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Survival Guide',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Know your rights. Know what to do.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Body
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Direkomendasikan
                        Text(
                          'Direkomendasikan',
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        allTopicsAsync.when(
                          data: (topics) {
                            if (topics.isEmpty) return const SizedBox.shrink();
                            
                            // Ambil topik pertama yang belum diselesaikan sebagai rekomendasi
                            FlashcardTopic? recommendedTopic;
                            for (var topic in topics) {
                              final progress = ref.watch(userFlashcardProgressProvider(topic.id)).valueOrNull;
                              if (progress == null || !progress.isCompleted) {
                                recommendedTopic = topic;
                                break;
                              }
                            }
                            recommendedTopic ??= topics.first; // fallback
                            
                            return _buildRecommendedCard(context, ref, recommendedTopic);
                          },
                          loading: () => const AppShimmerList(itemCount: 1, itemHeight: 100),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 32),

                        // Jelajahi Topik
                        Text(
                          'Jelajahi Topik',
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        categoriesAsync.when(
                          data: (categories) {
                            if (categories.isEmpty) {
                              return const Text('Belum ada kategori edukasi.');
                            }
                            return Column(
                              children: categories.map((cat) {
                                return _buildCategoryCard(context, ref, cat);
                              }).toList(),
                            );
                          },
                          loading: () => const AppShimmerList(itemCount: 3, itemHeight: 120),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),
                        
                        const SizedBox(height: 40), // Bottom padding
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRecommendedCard(BuildContext context, WidgetRef ref, FlashcardTopic topic) {
    // Watch user progress to show completion checkmark
    final progressAsync = ref.watch(userFlashcardProgressProvider(topic.id));
    
    final bool isCompleted = progressAsync.maybeWhen(
      data: (prog) => prog?.isCompleted ?? false,
      orElse: () => false,
    );

    // Dapatkan info kategori (asynchronous tapi kita berasumsi udah di-load di categoriesAsync)
    final categoriesAsync = ref.read(flashcardCategoriesProvider);
    final categoryName = categoriesAsync.valueOrNull?.firstWhere(
      (c) => c.id == topic.categoryId,
      orElse: () => throw Exception(),
    ).name ?? 'Topik';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.pushNamed(RouteNames.flashcardViewer, pathParameters: {'topicId': topic.id});
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic.title,
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${topic.totalCards} kartu • ±${topic.readTimeMinutes} mnt',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          if (isCompleted)
                            const Icon(Icons.check_circle, color: Colors.green, size: 16)
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '+${topic.xpReward} XP',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
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

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, dynamic cat) {
    // Hitung jumlah topik di dalam kategori ini
    final allTopicsAsync = ref.watch(allFlashcardTopicsProvider);
    final count = allTopicsAsync.valueOrNull?.where((t) => t.categoryId == cat.id).length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.pushNamed(RouteNames.categoryDetail, pathParameters: {'id': cat.id});
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (cat.description != null && cat.description!.isNotEmpty) ...[
                          Text(
                            cat.description!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          '$count panduan',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
