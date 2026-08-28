import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/onboarding_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirect();
    });
  }

  Future<void> _redirect() async {
    final uri = GoRouterState.of(context).uri;
    final skipDelay = uri.queryParameters['skip_delay'] == 'true';

    if (!skipDelay) {
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;

    final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();

    if (SupabaseService.isAuthenticated) {
      try {
        final profile = await SupabaseService.client
            .from('profiles')
            .select('id, interested_topics')
            .eq('id', SupabaseService.currentUser!.id)
            .single();

        final topics = profile['interested_topics'] as List<dynamic>? ?? [];

        if (mounted) {
          if (topics.isEmpty) {
            context.go(RouteNames.topicSelection);
          } else {
            context.go(RouteNames.home);
          }
        }
      } on PostgrestException catch (e) {
        // PGRST116 berarti data (baris) tidak ditemukan.
        // Ini terjadi jika akun user dihapus dari database.
        if (e.code == 'PGRST116') {
          await SupabaseService.client.auth.signOut();
          if (mounted) {
            SnackbarUtils.showError(context, 'Akun tidak ditemukan atau telah dihapus.');
            context.go(RouteNames.login);
          }
        } else {
          // Error database lainnya (server down sementara), fallback ke home
          if (mounted) context.go(RouteNames.home);
        }
      } on AuthException catch (_) {
        // Error terkait autentikasi (token tidak valid/expired)
        await SupabaseService.client.auth.signOut();
        if (mounted) {
          SnackbarUtils.showError(context, 'Sesi berakhir. Silakan masuk kembali');
          context.go(RouteNames.login);
        }
      } catch (e) {
        // Error jaringan (offline / timeout)
        // Jangan paksa logout! Biarkan masuk ke Home menggunakan cache lokal.
        if (mounted) context.go(RouteNames.home);
      }
    } else {
      if (!hasSeenOnboarding) {
        if (mounted) context.go(RouteNames.onboarding);
      } else {
        if (mounted) context.go(RouteNames.login);
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
