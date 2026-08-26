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
import '../../../chatbot/presentation/widgets/ai_fab.dart';
import '../../../chatbot/providers/chatbot_provider.dart';
import '../../domain/policy_model.dart';
import '../../providers/policy_provider.dart';
import '../../providers/article_read_provider.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String policyId;

  const ArticleDetailScreen({super.key, required this.policyId});

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 50) {
      // User almost reached the bottom
      ref.read(articleReadProvider(widget.policyId).notifier).setReachedBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch article data
    final policyAsync = ref.watch(policyDetailProvider(widget.policyId));
    
    // Anchor the chatbot state so history persists while viewing this article
    ref.watch(chatbotProvider(widget.policyId));
    
    // Watch anti-farming state to show snackbar
    ref.listen<AsyncValue<bool>>(articleReadProvider(widget.policyId), (previous, next) {
      if (next.value == true && previous?.value != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                const Text('Hebat! Kamu dapat +10 XP dari membaca!'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: policyAsync.maybeWhen(
        data: (policy) => AiFab(
          policyId: policy.id,
          articleContext: '${policy.title}\n${policy.fullContent}',
        ),
        orElse: () => null,
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            onPressed: () {
              // TODO: Implement Bookmark
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Implement Share
            },
          ),
        ],
      ),
      body: policyAsync.when(
        data: (policy) => _buildContent(policy),
        loading: () => const Padding(
          padding: EdgeInsets.all(24.0),
          child: AppShimmerList(itemCount: 3, itemHeight: 200),
        ),
        error: (error, stack) => AppErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(policyDetailProvider(widget.policyId)),
        ),
      ),

    );
  }

  Widget _buildContent(PolicyModel policy) {
    final categoryColor = AppColors.getCategoryColor(policy.category);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        left: AppSizes.p24,
        right: AppSizes.p24,
        top: AppSizes.p8,
        bottom: 120, // Space for Bottom Action
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              policy.category.toUpperCase(),
              style: AppTextStyles.labelMedium.copyWith(color: categoryColor),
            ),
          ),
          const SizedBox(height: AppSizes.p16),

          // Title
          Text(
            policy.title,
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 12),

          // Metadata Row (Source, Time)
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.border,
                child: Icon(Icons.account_balance, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                policy.sourceName ?? 'Sumber Resmi',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: AppColors.textTertiary)),
              ),
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${policy.estimatedReadMinutes} mnt baca',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p32),

          // Impact Box
          if (policy.impactDescription != null)
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.r12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dampaknya buat kamu:',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          policy.impactDescription!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSizes.p32),

          // AI Summary Points
          if (policy.aiSummary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.p20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSizes.r16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text('Ringkasan AI', style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...policy.aiSummary.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildSummaryPoint('0$index', entry.value),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p32),
          ],

          // Full Content Text
          Text(
            policy.fullContent,
            style: AppTextStyles.bodyLarge,
          ),
          
          const SizedBox(height: AppSizes.p48),
          
          // Vote Action
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.goNamed(RouteNames.vote, pathParameters: {'id': policy.id});
                },
                icon: const Icon(Icons.how_to_vote_rounded),
                label: const Text('Mulai Swipe Voting'),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          Center(
            child: Text(
              'Baca sampai habis untuk dapat +10 XP!',
              style: AppTextStyles.caption.copyWith(color: AppColors.support),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryPoint(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
