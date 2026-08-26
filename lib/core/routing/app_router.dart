import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../../core/widgets/app_error_widget.dart';
import 'package:flutter/material.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/article_detail_screen.dart';
import '../../features/voting/presentation/screens/vote_screen.dart';
import '../../features/trending/presentation/screens/trending_screen.dart';
import '../../features/education/presentation/screens/education_screen.dart';
import '../../features/education/presentation/screens/flashcard_viewer_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../services/supabase_service.dart';
import '../widgets/main_shell.dart';
import 'route_names.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// GoRouter configuration for Kawal.Z
final goRouter = GoRouter(
  initialLocation: RouteNames.splash,
  refreshListenable: GoRouterRefreshStream(SupabaseService.authStateChanges),
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final isLoggedIn = SupabaseService.isAuthenticated;
    final currentPath = state.matchedLocation;
    final fullUri = state.uri.toString();

    // // Intercept deep link Supabase yang masuk (native URL)
    // if (fullUri.contains('login-callback')) {
    //   return RouteNames.splash;
    // }

    final isAuthRoute = currentPath == RouteNames.login ||
        currentPath == RouteNames.register;
    final isSplash = currentPath == RouteNames.splash;

    // Splash handles its own redirect
    if (isSplash) return null;

    // Not logged in & not on auth page -> redirect to login
    if (!isLoggedIn && !isAuthRoute) return RouteNames.login;

    // Logged in & on auth page -> redirect to home
    if (isLoggedIn && isAuthRoute) return RouteNames.home;

    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.p16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.explore_off_rounded,
            size: 64,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        Text(
          'Tersesat? (404)',
          style: AppTextStyles.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          'Halaman atau rute yang kamu tuju tidak ditemukan.\nMungkin halamannya sudah dihapus atau linknya salah.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.p32),
        ElevatedButton.icon(
          onPressed: () => context.go(RouteNames.splash),
          icon: const Icon(Icons.home_rounded),
          label: const Text('Kembali ke Beranda'),
        ),
          ],
        ),
      ),
    ),
  ),
  routes: [
    // === AUTH ROUTES ===
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.register,
      builder: (context, state) => const RegisterScreen(),
    ),

    // === MAIN APP (with Bottom Navigation) ===
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Beranda
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  name: RouteNames.articleDetail,
                  path: RouteNames.articleDetail,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return ArticleDetailScreen(policyId: id);
                  },
                ),
                GoRoute(
                  name: RouteNames.vote,
                  path: RouteNames.vote,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return VoteScreen(policyId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 1: Trending
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.trending,
              builder: (context, state) => const TrendingScreen(),
            ),
          ],
        ),

        // Tab 2: Edukasi
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.education,
              builder: (context, state) => const EducationScreen(),
              routes: [
                GoRoute(
                  name: RouteNames.flashcardViewer,
                  path: RouteNames.flashcardViewer,
                  builder: (context, state) {
                    final id = state.pathParameters['topicId']!;
                    // We will create FlashcardViewerScreen next
                    return FlashcardViewerScreen(topicId: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 3: Leaderboard / Rank
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.leaderboard,
              builder: (context, state) => const LeaderboardScreen(),
            ),
          ],
        ),

        // Tab 4: Profil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
