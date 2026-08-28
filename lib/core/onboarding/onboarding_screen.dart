import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      number: '01',
      title: 'Pahami Isu Nyata',
      description:
          'Ikuti perkembangan kebijakan dan isu publik yang berdampak langsung ke hidupmu disajikan singkat, jelas, dan tepercaya.',
    ),
    OnboardingPage(
      number: '02',
      title: 'Suaramu Dihitung',
      description:
          'Berikan pendapat terstrukturmu tentang isu publik. Bukan sekadar like suaramu membentuk gambaran sentimen nyata.',
    ),
    OnboardingPage(
      number: '03',
      title: 'Kenali Hakmu',
      description:
          'Survival Guide hadir untuk bantu kamu navigasi dunia nyata dari hak karyawan sampai kebebasan berekspresi.',
    ),
  ];

  void _onNextPressed() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page: navigate to login and mark onboarding as complete
      await OnboardingService.setOnboardingComplete();
      if (mounted) {
        context.go(RouteNames.login);
      }
    }
  }

  void _onSkipPressed() async {
    await OnboardingService.setOnboardingComplete();
    if (mounted) context.go(RouteNames.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Logo / Header - just some top padding
            const SizedBox(height: AppSizes.p32),
            const SizedBox(height: AppSizes.p24),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return OnboardingPageContent(
                    page: _pages[index],
                  );
                },
              ),
            ),

            // Dot Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentPage ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: index == _currentPage
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p32),

            // Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.p12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Mulai Sekarang'
                        : 'Selanjutnya',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Skip Button (only show on first 2 pages)
            if (_currentPage < _pages.length - 1)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSizes.p16,
                  bottom: AppSizes.p32,
                ),
                child: TextButton(
                  onPressed: _onSkipPressed,
                  child: Text(
                    'Lewati',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: 48 + AppSizes.p16 + AppSizes.p32),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String number;
  final String title;
  final String description;

  OnboardingPage({
    required this.number,
    required this.title,
    required this.description,
  });
}

class OnboardingPageContent extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageContent({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/icons/kawalz_logo.png',
            width: 160,
            height: 160,
          ),
          const SizedBox(height: AppSizes.p32),

          // Title
          Text(
            page.title,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p16),

          // Description
          Text(
            page.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
