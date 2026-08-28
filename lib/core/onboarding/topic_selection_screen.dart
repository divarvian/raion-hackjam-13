import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routing/route_names.dart';
import '../../../features/profile/data/profile_repository.dart';
import '../../../core/utils/snackbar_utils.dart';

class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  final List<String> _availableTopics = [
    'Politik',
    'Ekonomi',
    'Sosial',
    'Hukum',
    'Lingkungan',
    'Pendidikan',
    'Kesehatan',
    'Teknologi',
  ];

  final Set<String> _selectedTopics = {};
  bool _isLoading = false;

  Future<void> _onContinue() async {
    if (_selectedTopics.isEmpty) {
      SnackbarUtils.showError(context, 'Pilih minimal 1 topik');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ProfileRepository();
      await repo.updateInterestedTopics(_selectedTopics.toList());
      
      if (mounted) {
        context.go(RouteNames.home);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Gagal menyimpan preferensi');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        if (_selectedTopics.length < 3) {
          _selectedTopics.add(topic);
        } else {
          SnackbarUtils.showError(context, 'Maksimal 3 topik');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Pilih Minatmu',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih 1-3 topik yang ingin kamu ikuti',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.p32),

              // Topic Pills
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _availableTopics.map((topic) {
                      final isSelected = _selectedTopics.contains(topic);
                      return GestureDetector(
                        onTap: () => _toggleTopic(topic),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.bgLight,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            topic,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.p16),

              // Selected count indicator
              if (_selectedTopics.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p16),
                  child: Text(
                    '${_selectedTopics.length}/3 topik dipilih',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Continue Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Lanjut',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
