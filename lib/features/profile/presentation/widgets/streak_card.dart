import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../screens/streak_milestone_screen.dart';

class StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final List<String> streakHistory;

  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.streakHistory,
  });

  @override
  Widget build(BuildContext context) {
    final milestone = StreakMilestoneScreen.getCurrentMilestone(currentStreak);
    final nextMilestone = StreakMilestoneScreen.getNextMilestone(currentStreak);
    
    // Generate week days (Mon - Sun) for the current week
    final now = DateTime.now();
    // In Dart, weekday is 1 (Monday) to 7 (Sunday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDates = List.generate(7, (index) => monday.add(Duration(days: index)));

    return GestureDetector(
      onTap: () {
        context.push(
          '/profile/${RouteNames.profileStreak}',
          extra: {
            'currentStreak': currentStreak,
            'longestStreak': longestStreak,
          },
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.r20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Dark blue to blue
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background rings/decoration (optional)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 20),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppSizes.p20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Character Box
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.r16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              milestone.assetPath,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.p16),
                      
                      // Streak Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STREAK BELAJAR',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$currentStreak',
                                  style: AppTextStyles.headlineLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    'hari',
                                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              milestone.title,
                              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      
                      // Arrow to next milestone
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (nextMilestone != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${nextMilestone.targetDays}h',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.8), size: 14),
                                ),
                                Text(
                                  nextMilestone.title,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.8), size: 28),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSizes.p20),
                  
                  // Progress Bar to next milestone
                  if (nextMilestone != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: currentStreak / nextMilestone.targetDays,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          milestone.title,
                          style: AppTextStyles.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        Text(
                          nextMilestone.title,
                          style: AppTextStyles.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p20),
                  ],

                  // Weekly Days
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ...List.generate(7, (index) {
                          final date = weekDates[index];
                          final dateString = DateFormat('yyyy-MM-dd').format(date);
                          final isActive = streakHistory.contains(dateString);
                          
                          // S S R K J S M
                          final dayNames = ['S', 'S', 'R', 'K', 'J', 'S', 'M']; 
                          
                          return Column(
                            children: [
                              Text(
                                dayNames[index],
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primary : AppColors.divider,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: isActive
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : null,
                              ),
                            ],
                          );
                        }),
                        Column(
                          children: [
                            Text(
                              'Detail',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chevron_right_rounded, color: AppColors.info, size: 18),
                            ),
                          ],
                        ),
                      ],
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
}
