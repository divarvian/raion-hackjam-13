import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/utils/xp_calculator.dart';
import '../../providers/leaderboard_provider.dart';
import '../../../profile/providers/profile_provider.dart';

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        // Connected to network! Refresh the leaderboard data.
        ref.invalidate(topUsersProvider);
        ref.invalidate(userRankProvider);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topUsersAsync = ref.watch(topUsersProvider);
    final period = ref.watch(leaderboardPeriodProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(topUsersProvider);
          ref.invalidate(userRankProvider);
          try {
            await ref.read(topUsersProvider.future);
          } catch (_) {}
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // --- RED HEADER SECTION ---
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE94545), // Match Figma red
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row (Title & Filter)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Leaderboard',
                                      style: AppTextStyles.headlineMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Top warga aktif Kawal.Z',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildPeriodFilter(context, ref, period),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // User Rank Card
                            _buildUserRankCard(ref),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- WHITE BODY SECTION ---
                  const SizedBox(height: 24),

                  // Podium Section
                  topUsersAsync.when(
                    data: (users) {
                      if (users.isEmpty) return const SizedBox.shrink();
                      final top3 = users.take(3).toList();
                      return _buildPodium(top3, period);
                    },
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Expanded(child: AppShimmer(width: double.infinity, height: 140, borderRadius: 12)),
                          const SizedBox(width: 8),
                          const Expanded(child: AppShimmer(width: double.infinity, height: 170, borderRadius: 12)),
                          const SizedBox(width: 8),
                          const Expanded(child: AppShimmer(width: double.infinity, height: 120, borderRadius: 12)),
                        ],
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Ranking List 4-10
            if (!topUsersAsync.hasError && (topUsersAsync.value?.length ?? 0) > 3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERINGKAT 4–10',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            
            topUsersAsync.when(
              data: (users) {
                final rest = users.skip(3).toList();
                if (rest.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('Belum ada pengguna lain.')),
                    ),
                  );
                }
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final rank = index + 4;
                      final user = rest[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildRankListItem(rank, user, period),
                      );
                    },
                    childCount: rest.length,
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AppShimmerList(itemCount: 5, itemHeight: 60),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AppErrorWidget(error: error, onRetry: () => ref.invalidate(topUsersProvider)),
                ),
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilter(BuildContext context, WidgetRef ref, String currentPeriod) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC03030), // Darker red background for filter
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip('Minggu', 'weekly', currentPeriod, ref),
          _buildFilterChip('Bulan', 'monthly', currentPeriod, ref),
          _buildFilterChip('All', 'all', currentPeriod, ref),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue, WidgetRef ref) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: () {
        ref.read(leaderboardPeriodProvider.notifier).state = value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFE94545) : Colors.white.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUserRankCard(WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final userRankAsync = ref.watch(userRankProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFED5D5D), // Slightly lighter red
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (!userRankAsync.hasError)
            AppAvatar(
              radius: 22,
              avatarUrl: userProfile?['avatar_url'],
              name: userProfile?['full_name'] ?? userProfile?['username'] ?? 'M E',
              fixedBackgroundColor: Colors.white.withValues(alpha: 0.3),
            ),
          if (!userRankAsync.hasError) const SizedBox(width: 16),
          Expanded(
            child: userRankAsync.when(
              data: (data) {
                final rank = data['rank'] ?? 0;
                // Add dot separator for thousands if needed
                final total = _formatNumber(data['total_users'] ?? 0);
                final xp = _formatNumber(data['user_xp'] ?? 0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peringkatmu saat ini',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '#$rank',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                'dari $total pengguna',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'XP kamu',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                xp,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 100, height: 12, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Container(width: 150, height: 24, color: Colors.white.withValues(alpha: 0.3)),
                ],
              ),
              error: (_, __) => const Center(
                child: Text(
                  'Koneksi terputus. Tarik layar untuk muat ulang.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3, String period) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Juara 2
          if (top3.length >= 2)
            Expanded(child: _buildPodiumColumn(top3[1], 2, period)),
          const SizedBox(width: 8),
          // Juara 1
          if (top3.isNotEmpty)
            Expanded(flex: 1, child: _buildPodiumColumn(top3[0], 1, period)),
          const SizedBox(width: 8),
          // Juara 3
          if (top3.length >= 3)
            Expanded(child: _buildPodiumColumn(top3[2], 3, period)),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(Map<String, dynamic> user, int rank, String period) {
    final avatar = user['avatar_url'];
    final name = _formatName(user['full_name'] ?? user['username'] ?? 'User');
    final rawXp = period == 'weekly' ? user['weekly_xp'] : period == 'monthly' ? user['monthly_xp'] : user['total_xp'];
    final xp = _formatNumber(rawXp ?? 0);
    
    // Config based on rank
    double avatarRadius = rank == 1 ? 36 : 28;
    Color avatarBg = rank == 1 ? const Color(0xFFE94545) : rank == 2 ? const Color(0xFF1CB068) : const Color(0xFFF09A0A);
    Color blockColor = rank == 1 ? const Color(0xFFE94545) : const Color(0xFFF2F2F2);
    Color blockTextColor = rank == 1 ? Colors.white : Colors.grey.shade500;
    Color nameColor = Colors.black;
    Color xpColor = rank == 1 ? const Color(0xFFE94545) : Colors.grey.shade600;
    double blockHeight = rank == 1 ? 120 : rank == 2 ? 100 : 80;
    
    // Custom Medals matching the image
    String medalIcon = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: EdgeInsets.all(rank == 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: rank == 1 ? const Color(0xFFFFDADA) : Colors.transparent, // faint glow for rank 1
                shape: BoxShape.circle,
              ),
              child: AppAvatar(
                radius: avatarRadius,
                avatarUrl: avatar,
                name: name,
                fixedBackgroundColor: avatarBg,
              ),
            ),
            Positioned(
              top: -16,
              child: Text(medalIcon, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, color: nameColor, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$xp XP',
          style: TextStyle(color: xpColor, fontWeight: FontWeight.bold, fontSize: 10),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: blockHeight,
          decoration: BoxDecoration(
            color: blockColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Juara $rank',
              style: TextStyle(
                color: blockTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankListItem(int rank, Map<String, dynamic> user, String period) {
    final avatar = user['avatar_url'];
    final rawName = user['full_name'] ?? user['username'] ?? 'User';
    final name = _formatName(rawName);
    final rawXp = period == 'weekly' ? user['weekly_xp'] : period == 'monthly' ? user['monthly_xp'] : user['total_xp'];
    final xp = _formatNumber(rawXp ?? 0);
    final level = user['level'] ?? 5;
    final levelName = XpCalculator.getLevelTitle(level);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppAvatar(
            radius: 20,
            avatarUrl: avatar,
            name: rawName,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  levelName,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7DD), // Light yellow background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on_rounded, color: Color(0xFFD67711), size: 14), // Orange icon
                const SizedBox(width: 2),
                Text(
                  xp,
                  style: const TextStyle(color: Color(0xFFD67711), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'User';
    if (parts.length == 1) return parts[0];
    return '${parts[0]}'; // Based on image, it just uses the first name mostly
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final whole = number ~/ 1000;
      final part = number % 1000;
      return '$whole.${part.toString().padLeft(3, '0')}';
    }
    return number.toString();
  }
}
