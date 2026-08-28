import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/utils/xp_calculator.dart';
import '../../providers/profile_provider.dart';

/// Profile Screen — Pengaturan & Statistik User
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            try {
              await ref.read(userProfileProvider.future);
            } catch (_) {}
          },
          child: profileAsync.when(
            data: (profile) {
              final level = profile['level'] ?? 5;
              final totalXp = profile['total_xp'] ?? 0;
              final avatar = profile['avatar_url'];
              final name = profile['full_name'] ?? profile['username'] ?? 'User';
              final totalVotes = profile['total_votes'] ?? 0;
              final totalReads = profile['total_articles_read'] ?? 0;
              final weeklyXp = profile['weekly_xp'] ?? 0;

              final levelName = XpCalculator.getLevelTitle(level);
              final nextXp = XpCalculator.xpForNextLevel(level);
              final currentXpStr = totalXp.toString();
              final maxLevel = level == 1;

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        child: Column(
                          children: [
                            const SizedBox(height: AppSizes.p8),

                  // Profile Header
                  Column(
                    children: [
                      // Avatar
                      AppAvatar(
                        radius: 44,
                        avatarUrl: avatar,
                        name: name,
                      ),
                      const SizedBox(height: AppSizes.p12),

                      // Name
                      Text(
                        name,
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level $level • $levelName',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p20),

                  // XP Progress
                  Container(
                    padding: const EdgeInsets.all(AppSizes.p20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress XP', style: AppTextStyles.titleMedium),
                            Text(
                              maxLevel ? 'MAX LEVEL' : '$currentXpStr / $nextXp XP',
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: maxLevel ? 1.0 : (totalXp / nextXp),
                            minHeight: 12,
                            backgroundColor: AppColors.divider,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!maxLevel)
                          Text(
                            'Kumpulkan ${nextXp - totalXp} XP lagi untuk naik level!',
                            style: AppTextStyles.caption,
                          )
                        else
                          Text(
                            'Selamat! Kamu sudah mencapai level tertinggi.',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p20),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Vote', totalVotes.toString(), Icons.how_to_vote)),
                      const SizedBox(width: AppSizes.p12),
                      Expanded(child: _buildStatCard('Artikel Dibaca', totalReads.toString(), Icons.menu_book)),
                      const SizedBox(width: AppSizes.p12),
                      Expanded(child: _buildStatCard('XP Mingguan', weeklyXp.toString(), Icons.emoji_events)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Menu List
                  _buildMenuItem(
                    icon: Icons.how_to_vote_outlined,
                    title: 'Voting History',
                    onTap: () {
                      // TODO: Navigate to voting history
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.bookmark_outline_rounded,
                    title: 'Simpan Artikel',
                    onTap: () {
                      // TODO: Navigate to saved articles
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan Akun',
                    onTap: () {
                      // TODO: Navigate to settings
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Keamanan & Privasi',
                    onTap: () {
                      // TODO: Navigate to privacy
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Kawal.Z',
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSizes.p8),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    isDestructive: true,
                    onTap: () async {
                      await GoogleSignIn().signOut();
                      await SupabaseService.client.auth.signOut();
                      ref.invalidate(userProfileProvider);
                      if (context.mounted) context.go(RouteNames.login);
                    },
                  ),
                    ],
                  ),
                ),
              ),
            ); // SingleChildScrollView
          },
        ); // LayoutBuilder
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSizes.p16),
        child: AppShimmerList(itemCount: 4, itemHeight: 100),
      ),
          error: (e, s) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: AppErrorWidget(
                  error: e,
                  onRetry: () => ref.invalidate(userProfileProvider),
                ),
              ),
            ],
          ), // CustomScrollView
        ), // profileAsync.when
        ), // RefreshIndicator
      ), // SafeArea
    ); // Scaffold
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p16, horizontal: AppSizes.p8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.reject : AppColors.textPrimary;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(color: color),
      ),
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
    );
  }
}
