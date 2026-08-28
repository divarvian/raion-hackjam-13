import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:intl/intl.dart';
import '../../providers/profile_provider.dart';
import '../../../voting/providers/vote_provider.dart';
import '../widgets/streak_card.dart';

/// Profile Screen — Pengaturan & Statistik User
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final voteHistoryAsync = ref.watch(userVoteHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: RefreshIndicator(
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
            final totalFlashcards = profile['total_flashcards_completed'] ?? 0;
            
            final currentStreak = profile['current_streak'] ?? 0;
            final longestStreak = profile['longest_streak'] ?? 0;
            final streakHistoryList = (profile['streak_history'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            final interestedTopics = (profile['interested_topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

            final levelName = XpCalculator.getLevelTitle(level);
            final nextXp = XpCalculator.xpForNextLevel(level);
            final currentXpStr = totalXp.toString();
            final maxLevel = level == 1;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Red Header Section
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSizes.p16),
                              
                              // Profile Header Row
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      AppAvatar(
                                        radius: 36,
                                        avatarUrl: avatar,
                                        name: name,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: GestureDetector(
                                          onTap: () => _showEditProfileBottomSheet(context, name, avatar),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: AppSizes.p16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: AppTextStyles.headlineSmall.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Level $level — $levelName',
                                          style: AppTextStyles.labelMedium.copyWith(
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: AppSizes.p24),
                              
                              // Progress bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Progress ke Level ${level > 1 ? level - 1 : level}',
                                          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                                        ),
                                        Text(
                                          maxLevel ? 'MAX LEVEL' : '$currentXpStr / $nextXp XP',
                                          style: AppTextStyles.labelMedium.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: maxLevel ? 1.0 : (totalXp / nextXp),
                                        minHeight: 6,
                                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: AppSizes.p24),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Stats Row (Full width)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.divider.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(child: _buildStatItem(totalReads.toString(), 'Artikel Dibaca')),
                              const VerticalDivider(width: 1, color: AppColors.divider),
                              Expanded(child: _buildStatItem(totalVotes.toString(), 'Suara Diberikan')),
                              const VerticalDivider(width: 1, color: AppColors.divider),
                              Expanded(child: _buildStatItem(totalFlashcards.toString(), 'Guide Selesai')),
                            ],
                          ),
                        ),
                      ),
                      
                      // Rest of the content on grey background
                      Padding(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                              
                              // Streak Belajar Card
                              StreakCard(
                                currentStreak: currentStreak,
                                longestStreak: longestStreak,
                                streakHistory: streakHistoryList,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Suara yang Pernah Kamu Berikan
                              Text(
                                'Suara yang Pernah Kamu Berikan',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              
                              voteHistoryAsync.when(
                                data: (history) {
                                  if (history.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text('Belum ada suara yang diberikan.'),
                                    );
                                  }
                                  return Column(
                                    children: history.map((vote) {
                                      final title = vote['policies']?['title'] ?? 'Kebijakan Tidak Diketahui';
                                      final voteType = vote['vote_type'] as String;
                                      
                                      String statusText;
                                      Color statusColor;
                                      if (voteType == 'support') {
                                        statusText = 'Setuju';
                                        statusColor = AppColors.support;
                                      } else if (voteType == 'reject') {
                                        statusText = 'Tidak Setuju';
                                        statusColor = AppColors.reject;
                                      } else {
                                        statusText = 'Netral';
                                        statusColor = AppColors.warning;
                                      }
                                      
                                      final rawDate = vote['created_at'];
                                      String formattedDate = '';
                                      if (rawDate != null) {
                                        final dt = DateTime.parse(rawDate).toLocal();
                                        formattedDate = DateFormat('d MMM yyyy').format(dt); // Using default locale since we might not have id_ID initialized
                                      }
                                      
                                      final policyId = vote['policy_id'] as String?;
                                      
                                      return _buildMockVoteHistory(
                                        title, 
                                        statusText, 
                                        formattedDate, 
                                        statusColor,
                                        onTap: policyId != null ? () => context.push('/home/article/$policyId') : null,
                                      );
                                    }).toList(),
                                  );
                                },
                                loading: () => const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                error: (err, stack) => Text('Error loading history: $err'),
                              ),
                              
                              const SizedBox(height: AppSizes.p16),
                              
                              // Minatmu
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Minatmu',
                                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Edit',
                                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: interestedTopics.isEmpty 
                                  ? [const Text('Belum ada topik yang dipilih.')]
                                  : interestedTopics.map((topic) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: AppColors.divider),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Text(
                                          topic,
                                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              
                              const SizedBox(height: AppSizes.p24),
                              
                              Text(
                                'Pengaturan',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSizes.p12),
                              
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppSizes.r16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    children: [
                                      _buildSettingsItem(
                                        Icons.edit_outlined, 
                                        'Edit Profil', 
                                        'Ubah nama tampilan & foto', 
                                        true,
                                        onTap: () => _showEditProfileBottomSheet(context, name, avatar),
                                      ),
                                    const Divider(height: 1, color: AppColors.divider),
                                    _buildSettingsItem(Icons.star_border_rounded, 'Topik Minat', 'Sesuaikan konten untukmu', true),
                                    const Divider(height: 1, color: AppColors.divider),
                                    _buildSettingsItem(Icons.settings_outlined, 'Pengaturan Akun', 'Notifikasi & privasi', true),
                                    const Divider(height: 1, color: AppColors.divider),
                                    _buildSettingsItem(Icons.help_outline_rounded, 'Bantuan & Dukungan', '', true),
                                    const Divider(height: 1, color: AppColors.divider),
                                    _buildSettingsItem(Icons.lock_outline_rounded, 'Privasi', '', true),
                                  ],
                                ),
                              ),
                            ),
                              
                              const SizedBox(height: AppSizes.p16),
                              
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppSizes.r16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Material(
                                  color: Colors.transparent,
                                  child: _buildSettingsItem(
                                    Icons.logout_rounded, 
                                    'Keluar', 
                                    '', 
                                    false, 
                                    isDestructive: true,
                                    onTap: () async {
                                      await GoogleSignIn().signOut();
                                      await SupabaseService.client.auth.signOut();
                                      ref.invalidate(userProfileProvider);
                                      ref.invalidate(userVoteHistoryProvider);
                                      if (context.mounted) context.go(RouteNames.login);
                                    },
                                  ),
                                ),
                              ),
                              
                            const SizedBox(height: AppSizes.p32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.p16),
              child: AppShimmerList(itemCount: 4, itemHeight: 100),
            ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle, bool showArrow, {bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? AppColors.primary : AppColors.textPrimary;
    
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle.isNotEmpty 
          ? Text(subtitle, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary))
          : null,
      trailing: showArrow ? const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildMockVoteHistory(String title, String status, String date, Color statusColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.bar_chart_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.labelSmall.copyWith(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('• $date', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
        ],
      ),
    ),
    );
  }

  Future<void> _showEditProfileBottomSheet(BuildContext context, String currentName, String? currentAvatarUrl) async {
    final TextEditingController nameController = TextEditingController(text: currentName);
    bool isLoading = false;
    File? selectedImage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: AppSizes.p24,
              right: AppSizes.p24,
              top: AppSizes.p24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profil',
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p24),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgLight,
                          image: selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : (currentAvatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(currentAvatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: selectedImage == null && currentAvatarUrl == null
                            ? Center(
                                child: Text(
                                  currentName.isNotEmpty ? currentName[0].toUpperCase() : 'U',
                                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: isLoading
                              ? null
                              : () async {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (context) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.photo_library),
                                            title: const Text('Pilih dari Galeri'),
                                            onTap: () async {
                                              Navigator.of(context).pop();
                                              final XFile? image = await _picker.pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 1024,
                                                maxHeight: 1024,
                                                imageQuality: 85,
                                              );
                                              if (image != null) {
                                                setModalState(() => selectedImage = File(image.path));
                                              }
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.camera_alt),
                                            title: const Text('Ambil Foto'),
                                            onTap: () async {
                                              Navigator.of(context).pop();
                                              final XFile? image = await _picker.pickImage(
                                                source: ImageSource.camera,
                                                maxWidth: 1024,
                                                maxHeight: 1024,
                                                imageQuality: 85,
                                              );
                                              if (image != null) {
                                                setModalState(() => selectedImage = File(image.path));
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.p32),
                Text(
                  'Nama Tampilan',
                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.p8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama Anda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.bgLight.withValues(alpha: 0.5),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSizes.p32),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          if (newName.isEmpty) {
                            return;
                          }

                          setModalState(() => isLoading = true);
                          try {
                            final repo = ref.read(profileRepositoryProvider);
                            bool updated = false;

                            if (selectedImage != null) {
                              await repo.updateAvatar(selectedImage!);
                              updated = true;
                            }

                            if (newName != currentName) {
                              await repo.updateProfileName(newName);
                              updated = true;
                            }

                            if (updated) {
                              ref.invalidate(userProfileProvider);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profil berhasil diperbarui')),
                                );
                              }
                            } else {
                              if (context.mounted) Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal memperbarui profil: $e'), backgroundColor: Colors.red),
                              );
                            }
                            setModalState(() => isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: AppSizes.p24),
              ],
            ),
          );
        },
      ),
    );
  }
}
