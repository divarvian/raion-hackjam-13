import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/utils/xp_calculator.dart';
import '../../providers/leaderboard_provider.dart';

/// Leaderboard Screen — Weekly Civic League
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topUsersAsync = ref.watch(topUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(topUsersProvider);
            try {
              await ref.read(topUsersProvider.future);
            } catch (_) {}
          },
          child: topUsersAsync.hasError
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    child: AppErrorWidget(
                      error: topUsersAsync.error!,
                      onRetry: () => ref.invalidate(topUsersProvider),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Leaderboard', style: AppTextStyles.headlineMedium),
                  IconButton(
                    onPressed: () {
                      // TODO: Show level info
                    },
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ],
              ),
              Text(
                'XP tertinggi minggu ini',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSizes.p16),

              // Period & countdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text('Minggu Ini', style: AppTextStyles.titleMedium),
                      ],
                    ),
                    Text(
                      'Berakhir hari Minggu',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              topUsersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const Center(child: Text('Belum ada data leaderboard.'));
                  }

                  final top3 = users.take(3).toList();
                  final rest = users.skip(3).toList();

                  return Column(
                    children: [
                      // Top 3 Podium
                      _buildPodium(top3),
                      const SizedBox(height: AppSizes.p24),

                      // Ranking list #4-10
                      if (rest.isNotEmpty)
                        ...rest.asMap().entries.map((e) {
                          final rank = e.key + 4;
                          final user = e.value;
                          final rawName = user['full_name'] ?? user['username'] ?? 'User';
                          return _buildRankItem(
                            rank,
                            _formatName(rawName),
                            user['level'] ?? 5,
                            user['weekly_xp'] ?? 0,
                            user['avatar_url'],
                          );
                        }),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: AppShimmerList(itemCount: 5, itemHeight: 80),
                ),
                  error: (error, stack) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSizes.p16),

              // How to earn XP
              Container(
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cara Dapat XP', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildXpGuide(
                            Icons.chrome_reader_mode_rounded,
                            '+10 XP',
                            'Baca',
                          ),
                        ),
                        Expanded(
                          child: _buildXpGuide(
                            Icons.how_to_vote_rounded,
                            '+20 XP',
                            'Vote',
                          ),
                        ),
                        Expanded(
                          child: _buildXpGuide(
                            Icons.forum_rounded,
                            '+5 XP',
                            'Komen',
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p24),
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

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2
              if (top3.length >= 2)
                _buildPodiumUser(
                  user: top3[1],
                  rank: 2,
                  height: 140,
                  color: Colors.grey.shade300,
                  badgeColor: Colors.grey.shade600,
                ),

              const SizedBox(width: 16),

              // Rank 1
              if (top3.isNotEmpty)
                _buildPodiumUser(
                  user: top3[0],
                  rank: 1,
                  height: 170,
                  color: AppColors.accent.withValues(alpha: 0.2),
                  badgeColor: AppColors.accent,
                ),

              const SizedBox(width: 16),

              // Rank 3
              if (top3.length >= 3)
                _buildPodiumUser(
                  user: top3[2],
                  rank: 3,
                  height: 120,
                  color: Colors.brown.shade200,
                  badgeColor: Colors.brown,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser({
    required Map<String, dynamic> user,
    required int rank,
    required double height,
    required Color color,
    required Color badgeColor,
  }) {
      final avatar = user['avatar_url'];
    final rawName = user['full_name'] ?? user['username'] ?? 'User';
    final name = _formatName(rawName);
    final xp = user['weekly_xp'] ?? 0;
    final level = user['level'] ?? 5;
    final levelName = XpCalculator.getLevelTitle(level);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 32 : 28,
              backgroundColor: color,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null
                  ? Icon(Icons.person, color: badgeColor)
                  : null,
            ),
            Positioned(
              bottom: -8,
              left: 0,
              right: 0,
              child: Center(
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: badgeColor,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: height,
          width: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  name,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  levelName,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$xp XP',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankItem(int rank, String name, int level, int xp, String? avatar) {
    final levelName = XpCalculator.getLevelTitle(level);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  levelName,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '$xp XP',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpGuide(IconData icon, String xp, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(xp,
            style:
                AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  String _formatName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'User';
    if (parts.length == 1) return parts[0];
    
    // First name + Initial of second name
    return '${parts[0]} ${parts[1][0].toUpperCase()}.';
  }
}
