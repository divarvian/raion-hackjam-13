import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/policy_model.dart';
import '../../providers/policy_provider.dart';

/// Beranda — What's Up Indonesia (AI TL;DR Feed)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch data via Riverpod
    final topTrendingAsync = ref.watch(topTrendingPolicyProvider);
    final recentPoliciesAsync = ref.watch(recentPoliciesProvider);

    // Get user name (fallback to "User" if not set in metadata yet)
    final user = SupabaseService.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Warga';
    final firstName = fullName.split(' ').first;

    final hasGlobalError = topTrendingAsync.hasError || recentPoliciesAsync.hasError;
    final globalError = topTrendingAsync.error ?? recentPoliciesAsync.error;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Force refresh providers
            ref.invalidate(topTrendingPolicyProvider);
            ref.invalidate(recentPoliciesProvider);
            try {
              await ref.read(topTrendingPolicyProvider.future);
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
                        ref.invalidate(topTrendingPolicyProvider);
                        ref.invalidate(recentPoliciesProvider);
                      },
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.p8),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $firstName 👋',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "What's up, Indonesia?",
                          style: AppTextStyles.headlineMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_outlined, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                // Subtitle
                Text(
                  '🔥 isu penting hari ini',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.p12),

                // Trending Hero Card
                topTrendingAsync.when(
                  data: (policy) {
                    if (policy == null) {
                      return _buildEmptyState(
                        'Belum ada isu trending hari ini.',
                      );
                    }
                    return _buildTrendingHeroCard(context, policy);
                  },
                  loading: () => _buildHeroShimmer(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSizes.p24),

                // Latest Updates section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Isu lainnya untuk kamu',
                      style: AppTextStyles.titleLarge,
                    ),
                    TextButton(onPressed: () {}, child: const Text('See all')),
                  ],
                ),
                const SizedBox(height: AppSizes.p8),

                // Article list items
                recentPoliciesAsync.when(
                  data: (policies) {
                    if (policies.isEmpty) {
                      return _buildEmptyState('Belum ada isu baru.');
                    }
                    return Column(
                      children: policies
                          .map((policy) => _buildArticleItem(context, policy))
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: AppShimmerList(itemCount: 3, itemHeight: 90),
                  ),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingHeroCard(BuildContext context, PolicyModel policy) {
    return GestureDetector(
      onTap: () {
        // Navigate to detail
        context.go('/home/article/${policy.id}');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.p20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(AppSizes.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trending Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.reject,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'TRENDING',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              policy.title,
              style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              policy.subtitle ?? 'Apa yang sebenarnya berubah?',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),

            // AI TL;DR Box
            if (policy.aiSummary.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ringkasan AI',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...policy.aiSummary.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final text = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildSummaryPoint('0$index', text),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Read full story button
            Row(
              children: [
                Text(
                  'Read full story',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPoint(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildArticleItem(BuildContext context, PolicyModel policy) {
    final categoryColor = AppColors.getCategoryColor(policy.category);
    final dateFormatted = DateFormat('dd MMM yyyy').format(policy.publishedAt);

    return GestureDetector(
      onTap: () {
        context.go('/home/article/${policy.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.p12),
        padding: const EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.r12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.r8),
              ),
              child: Icon(Icons.article_outlined, color: categoryColor),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.category.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    policy.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(dateFormatted, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      alignment: Alignment.center,
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }


  Widget _buildHeroShimmer() {
    return const AppShimmer(
      width: double.infinity,
      height: 350,
      borderRadius: AppSizes.r16,
    );
  }
}
