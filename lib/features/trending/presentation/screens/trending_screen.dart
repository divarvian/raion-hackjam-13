import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../home/domain/policy_model.dart';
import '../../providers/trending_provider.dart';

/// Trending Screen — Sentimen Publik
class TrendingScreen extends ConsumerStatefulWidget {
  const TrendingScreen({super.key});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends ConsumerState<TrendingScreen> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingPoliciesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(trendingPoliciesProvider);
            try {
              await ref.read(trendingPoliciesProvider.future);
            } catch (_) {}
          },
          child: trendingAsync.hasError
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    child: AppErrorWidget(
                      error: trendingAsync.error!,
                      onRetry: () => ref.invalidate(trendingPoliciesProvider),
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
              const SizedBox(height: AppSizes.p16),
              // Header
              Text('Trending on Public', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 4),
              Text('Apa yang lagi ramai dibahas di Kawal.Z?', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSizes.p16),

              // Warning Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hasil polling di bawah ini murni opini warga Kawal.Z, bukan mewakili seluruh masyarakat Indonesia ya!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', null),
                    _buildFilterChip('Hype', null),
                    _buildFilterChip('Negatif', AppColors.reject),
                    _buildFilterChip('Positif', AppColors.support),
                    _buildFilterChip('Minggu Ini', null),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // Fetch Data
              trendingAsync.when(
                data: (policies) {
                  if (policies.isEmpty) {
                    return const Center(child: Text('Belum ada isu trending.'));
                  }

                  var filteredPolicies = policies.toList();
                  
                  // Filter Logic
                  if (_selectedFilter == 'Negatif') {
                    filteredPolicies = filteredPolicies.where((p) => p.rejectCount > p.supportCount && p.rejectCount > p.neutralCount).toList();
                  } else if (_selectedFilter == 'Positif') {
                    filteredPolicies = filteredPolicies.where((p) => p.supportCount > p.rejectCount && p.supportCount > p.neutralCount).toList();
                  } else if (_selectedFilter == 'Minggu Ini') {
                    final now = DateTime.now();
                    filteredPolicies = filteredPolicies.where((p) => now.difference(p.publishedAt).inDays <= 7).toList();
                  } else if (_selectedFilter == 'Hype') {
                    // Sort by total votes descending
                    filteredPolicies.sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
                  }

                  if (filteredPolicies.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text('Tidak ada isu untuk kategori ini.'),
                      ),
                    );
                  }

                  final heroPolicy = filteredPolicies.first;
                  final listPolicies = filteredPolicies.skip(1).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(context, heroPolicy),
                      const SizedBox(height: AppSizes.p16),
                      ...listPolicies.asMap().entries.map((entry) {
                        final index = entry.key + 2; // Start from rank 2
                        final policy = entry.value;
                        return _buildRankItem(context, index, policy);
                      }),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: AppShimmerList(itemCount: 5, itemHeight: 120),
                ),
                error: (error, stack) => const SizedBox.shrink(),
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

  Widget _buildFilterChip(String label, Color? dotColor) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.reject.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.reject : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isActive ? AppColors.reject : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, PolicyModel policy) {
    return GestureDetector(
      onTap: () => context.goNamed(RouteNames.articleDetail, pathParameters: {'id': policy.id}),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      policy.thumbnailUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(180),
                    ),
                  )
                else
                  _buildPlaceholderImage(180, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.reject,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '#1',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.category,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    policy.title,
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSegmentedProgressBar(policy, showLabels: true),
                  const SizedBox(height: 16),
                  Text(
                    '${policy.totalVotes} suara',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankItem(BuildContext context, int rank, PolicyModel policy) {
    return GestureDetector(
      onTap: () => context.goNamed(RouteNames.articleDetail, pathParameters: {'id': policy.id}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (policy.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  policy.thumbnailUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(80, width: 80, borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              _buildPlaceholderImage(80, width: 80, borderRadius: BorderRadius.circular(12)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.reject.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$rank',
                          style: const TextStyle(color: AppColors.reject, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        policy.category,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    policy.title,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildSegmentedProgressBar(policy, showLabels: false),
                  const SizedBox(height: 8),
                  Text(
                    '${policy.totalVotes} suara',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedProgressBar(PolicyModel policy, {required bool showLabels}) {
    // Prevent division by zero
    int total = policy.totalVotes == 0 ? 1 : policy.totalVotes;
    
    // Order: Reject (Red), Support (Green), Neutral (Yellow)
    int reject = policy.rejectCount;
    int support = policy.supportCount;
    int neutral = policy.neutralCount;

    // Handle empty state gracefully
    if (policy.totalVotes == 0) {
      reject = 1; support = 0; neutral = 0; // Default look if 0 votes
    }

    final rejectP = ((reject / total) * 100).round();
    final supportP = ((support / total) * 100).round();
    final neutralP = ((neutral / total) * 100).round();

    return Column(
      children: [
        if (showLabels) ...[
          Row(
            children: [
              if (reject > 0) Expanded(flex: reject, child: Text('$rejectP%', style: const TextStyle(color: AppColors.reject, fontWeight: FontWeight.bold, fontSize: 11))),
              if (support > 0) Expanded(flex: support, child: Text('$supportP%', style: const TextStyle(color: AppColors.support, fontWeight: FontWeight.bold, fontSize: 11))),
              if (neutral > 0) Expanded(flex: neutral, child: Text('$neutralP%', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (reject > 0) Expanded(flex: reject, child: Container(color: AppColors.reject)),
                if (support > 0) Expanded(flex: support, child: Container(color: AppColors.support)),
                if (neutral > 0) Expanded(flex: neutral, child: Container(color: AppColors.warning)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage(double height, {double? width, BorderRadius? borderRadius}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.image_outlined, color: Color(0xFF9CA3AF), size: 32),
    );
  }
}
