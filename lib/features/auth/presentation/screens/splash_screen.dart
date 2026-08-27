import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/services/topic_preference_service.dart';

/// Splash Screen — cek auth state lalu redirect
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();

    if (SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client
            .from('profiles')
            .select('id')
            .eq('id', SupabaseService.currentUser!.id)
            .single();

        if (mounted) context.go(RouteNames.home);
      } catch (e) {
        await SupabaseService.client.auth.signOut();
        if (mounted) {
          SnackbarUtils.showError(context, 'Sesi berakhir. Silakan masuk kembali');
          context.go(RouteNames.login);
        }
      }
    } else {
      if (!hasSeenOnboarding) {
        if (mounted) context.go(RouteNames.onboarding);
      } else {
        // Check if topics selected
        final hasTopics = await TopicPreferenceService.getInterestedTopics();
        if (hasTopics.isEmpty) {
          if (mounted) context.go(RouteNames.topicSelection);
        } else {
          if (mounted) context.go(RouteNames.login);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'KAWAL.Z',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adulting, but make it count.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
