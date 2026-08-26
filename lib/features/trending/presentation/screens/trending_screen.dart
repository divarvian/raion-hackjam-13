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
import '../../../home/domain/policy_model.dart';
import '../../providers/trending_provider.dart';

/// Trending Screen — Sentimen Publik
class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const SizedBox(height: AppSizes.p8),

              // Header
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: AppColors.accent, size: 28),
                  const SizedBox(width: 8),
                  Text('Trending Topics', style: AppTextStyles.headlineMedium),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Isu paling panas menurut Gen Z',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                'Data berdasarkan akumulasi voting terbanyak',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSizes.p24),

              // Fetch Data
              trendingAsync.when(
                data: (policies) {
                  if (policies.isEmpty) {
                    return const Center(child: Text('Belum ada isu trending.'));
                  }

                  // Top 3 for Podium
                  final podiumPolicies = policies.take(3).toList();
                  // The rest for Ranking List
                  final listPolicies = policies.skip(3).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          '🏆 Top 3 Isu Terpanas',
                          style: AppTextStyles.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p16),

                      // Podium cards (Rank 2, Rank 1, Rank 3)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (podiumPolicies.length > 1)
                            Expanded(child: _buildPodiumCard(context, podiumPolicies[1], 2, 80)),
                          const SizedBox(width: 8),
                          if (podiumPolicies.isNotEmpty)
                            Expanded(child: _buildPodiumCard(context, podiumPolicies[0], 1, 100)),
                          const SizedBox(width: 8),
                          if (podiumPolicies.length > 2)
                            Expanded(child: _buildPodiumCard(context, podiumPolicies[2], 3, 70)),
                        ],
                      ),
                      const SizedBox(height: AppSizes.p32),

                      if (listPolicies.isNotEmpty) ...[
                        Text('Peringkat Isu Lainnya', style: AppTextStyles.titleLarge),
                        const SizedBox(height: AppSizes.p12),
                        ...listPolicies.asMap().entries.map((entry) {
                          final index = entry.key + 4; // Start from rank 4
                          final policy = entry.value;
                          return _buildRankItem(context, index, policy);
                        }),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: AppShimmerList(itemCount: 5, itemHeight: 90),
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

  Widget _buildPodiumCard(BuildContext context, PolicyModel policy, int rank, double height) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;
    } else {
      rankColor = Colors.brown.shade300;
    }
    
    // Calculate reject percentage for hype
    final rejectPercent = policy.totalVotes > 0
        ? ((policy.rejectCount / policy.totalVotes) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.goNamed(RouteNames.articleDetail, pathParameters: {'id': policy.id}),
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: rankColor,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            padding: const EdgeInsets.all(AppSizes.p8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: rankColor, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  policy.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.thumb_down_rounded, size: 12, color: AppColors.reject),
                    const SizedBox(width: 4),
                    Text(
                      '$rejectPercent%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.reject,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(BuildContext context, int rank, PolicyModel policy) {
    final rejectPercent = policy.totalVotes > 0
        ? ((policy.rejectCount / policy.totalVotes) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.goNamed(RouteNames.articleDetail, pathParameters: {'id': policy.id}),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.p12),
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${policy.totalVotes} Votes',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.reject.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tolak $rejectPercent%',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.reject),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
