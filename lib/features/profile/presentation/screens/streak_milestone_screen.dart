import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class StreakMilestone {
  final int targetDays;
  final String title;
  final String assetPath;

  const StreakMilestone({
    required this.targetDays,
    required this.title,
    required this.assetPath,
  });
}

class StreakMilestoneScreen extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakMilestoneScreen({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  static const List<StreakMilestone> milestones = [
    StreakMilestone(targetDays: 1, title: 'Kawal.Z', assetPath: 'assets/streaks/WARGA.png'),
    StreakMilestone(targetDays: 3, title: 'Ketua RT', assetPath: 'assets/streaks/RT.png'),
    StreakMilestone(targetDays: 7, title: 'Pak Camat', assetPath: 'assets/streaks/CAMAT.png'),
    StreakMilestone(targetDays: 14, title: 'Polisi', assetPath: 'assets/streaks/POLICI.png'),
    StreakMilestone(targetDays: 30, title: 'Menteri', assetPath: 'assets/streaks/MENTRI.png'),
    StreakMilestone(targetDays: 365, title: 'Presiden', assetPath: 'assets/streaks/PRES.png'),
  ];

  static StreakMilestone getCurrentMilestone(int streak) {
    StreakMilestone current = milestones.first;
    for (final m in milestones) {
      if (streak >= m.targetDays) {
        current = m;
      } else {
        break;
      }
    }
    return current;
  }

  static StreakMilestone? getNextMilestone(int streak) {
    for (final m in milestones) {
      if (streak < m.targetDays) {
        return m;
      }
    }
    return null; // All unlocked
  }

  @override
  Widget build(BuildContext context) {
    final current = getCurrentMilestone(currentStreak);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate blue
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
          child: ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            label: Text('Kembali', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
          ),
        ),
        leadingWidth: 120,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEVEL SAAT INI',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                current.title,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currentStreak',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(
                      'hari berturut-turut',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSizes.p32),
              Text(
                'SEMUA MILESTONE',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: milestones.length,
                itemBuilder: (context, index) {
                  final milestone = milestones[index];
                  final isUnlocked = longestStreak >= milestone.targetDays;
                  final isCurrentTarget = !isUnlocked && (index == 0 || longestStreak >= milestones[index-1].targetDays);
                  final isCurrentStreak = currentStreak >= milestone.targetDays && (index == milestones.length - 1 || currentStreak < milestones[index+1].targetDays);

                  return Container(
                    decoration: BoxDecoration(
                      color: isUnlocked || isCurrentTarget 
                          ? const Color(0xFF1E40AF) // Bright blue for unlocked/target
                          : const Color(0xFF1E293B), // Dark gray for locked
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.p16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: isUnlocked 
                                          ? Colors.white.withValues(alpha: 0.1) 
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: Opacity(
                                            opacity: isUnlocked || isCurrentTarget ? 1.0 : 0.3,
                                            child: Image.asset(
                                              milestone.assetPath,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(
                                                Icons.person, 
                                                color: Colors.white.withValues(alpha: 0.5), 
                                                size: 50,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                milestone.title,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: isUnlocked || isCurrentTarget 
                                      ? Colors.white 
                                      : Colors.white.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                milestone.targetDays == 365 
                                    ? '∞ hari' 
                                    : '${isUnlocked ? milestone.targetDays : longestStreak}/${milestone.targetDays} hari',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isUnlocked || isCurrentTarget 
                                      ? Colors.white.withValues(alpha: 0.7) 
                                      : Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!isUnlocked)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: longestStreak / milestone.targetDays,
                                    minHeight: 4,
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        if (!isUnlocked)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.lock_outline, 
                              color: Colors.white.withValues(alpha: 0.3), 
                              size: 16,
                            ),
                          ),

                        if (isCurrentStreak)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6), // Blue background to stand out
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'SEKARANG',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
