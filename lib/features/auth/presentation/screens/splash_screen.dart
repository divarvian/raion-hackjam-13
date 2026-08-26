import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/supabase_service.dart';

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
    // Tunggu sebentar untuk splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (SupabaseService.isAuthenticated) {
      try {
        // Verifikasi keaktifan user (mencegah 'Ghost User' auto-login jika sudah dihapus)
        await SupabaseService.client
            .from('profiles')
            .select('id')
            .eq('id', SupabaseService.currentUser!.id)
            .single();

        if (mounted) context.go(RouteNames.home);
      } catch (e) {
        // Jika gagal (user dihapus atau session mati), paksa logout
        await SupabaseService.client.auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi kamu telah berakhir atau tidak valid. Silakan masuk kembali.'),
              backgroundColor: AppColors.reject,
            ),
          );
          context.go(RouteNames.login);
        }
      }
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 48,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'KAWAL.Z',
              style: AppTextStyles.headlineLarge.copyWith(
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adulting, but make it count.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
