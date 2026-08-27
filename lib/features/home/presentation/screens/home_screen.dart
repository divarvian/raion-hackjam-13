import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
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
            ref.invalidate(topTrendingPolicyProvider);
            ref.invalidate(recentPoliciesProvider);
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
                const SizedBox(height: AppSizes.p12),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat pagi,',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "What's up, ${_toCamelCase(firstName)}?",
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pantau isu yang sedang ramai!',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.reject,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          firstName.substring(0, 2).toUpperCase(),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                // Category Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryTab('Trending', true),
                      const SizedBox(width: 8),
                      _buildCategoryTab('For You', false),
                      const SizedBox(width: 8),
                      _buildCategoryTab('Policy Watch', false),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.p16),

                // Trending subtitle
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p16,
                    vertical: AppSizes.p12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDD7DC),
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                  child: Text(
                    'Trending di Kawal.Z minggu ini',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.reject,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSizes.p16),

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
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Lihat semua',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.reject,
                        ),
                      ),
                    ),
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
        context.go('/home/article/${policy.id}');
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (policy.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.r16),
                    ),
                    child: Image.network(
                      policy.thumbnailUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: const Color(0xFFE8E8E8),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Color(0xFFBDBDBD),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppSizes.r16),
                      ),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.reject,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Trending #1',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.reject.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      policy.category,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.reject,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    policy.title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    policy.subtitle ?? 'Apa yang sebenarnya berubah?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        '${policy.sourceName ?? 'Kompas.id'} · ${DateFormat('dd MMM yyyy').format(policy.publishedAt)} · ${policy.estimatedReadMinutes} mnt',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.reject,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${policy.totalVotes} Komentar',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (policy.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.r12),
                child: Image.network(
                  policy.thumbnailUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFFFDD7DC),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: Color(0xFFBDBDBD),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD7DC),
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      policy.category,
                      style: AppTextStyles.caption.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    policy.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$dateFormatted · 3 mnt',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isActive ? AppColors.reject : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.reject : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isActive ? Colors.white : AppColors.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
