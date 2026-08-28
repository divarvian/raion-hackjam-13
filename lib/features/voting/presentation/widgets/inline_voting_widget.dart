import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../home/domain/policy_model.dart';
import '../../providers/vote_provider.dart';
import 'package:intl/intl.dart';

class InlineVotingWidget extends ConsumerStatefulWidget {
  final PolicyModel policy;

  const InlineVotingWidget({super.key, required this.policy});

  @override
  ConsumerState<InlineVotingWidget> createState() => _InlineVotingWidgetState();
}

class _InlineVotingWidgetState extends ConsumerState<InlineVotingWidget> {
  String? _selectedOption;
  bool _hasVoted = false; // Local state to transition to result UI
  String? _submittedOption;

  bool _isCheckingVote = true; // State untuk loading awal

  final Map<String, String> _options = {
    'support': 'Setuju',
    'neutral': 'Netral',
    'reject': 'Tolak',
  };

  @override
  void initState() {
    super.initState();
    _checkUserVote();
  }

  Future<void> _checkUserVote() async {
    try {
      final repo = ref.read(voteRepositoryProvider);
      final voteType = await repo.getUserVote(widget.policy.id);
      if (mounted) {
        if (voteType != null) {
          setState(() {
            _hasVoted = true;
            _submittedOption = voteType;
            _isCheckingVote = false;
          });
        } else {
          setState(() {
            _isCheckingVote = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingVote = false;
        });
      }
    }
  }

  void _submitVote() async {
    if (_selectedOption == null) return;

    try {
      await ref.read(voteProvider.notifier).castVote(
        policyId: widget.policy.id,
        voteType: _selectedOption!,
      );
      
      final voteState = ref.read(voteProvider);
      if (voteState.hasError) {
        if (mounted) {
          SnackbarUtils.showError(context, voteState.error.toString());
        }
      } else {
        setState(() {
          _hasVoted = true;
          _submittedOption = _selectedOption;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Gagal mengirim suara.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingVote) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_hasVoted) {
      return _buildResultUI();
    }
    return _buildVotingUI();
  }

  Color _getOptionColor(String key) {
    switch (key) {
      case 'support':
        return AppColors.support; // Hijau
      case 'neutral':
        return AppColors.warning; // Oranye
      case 'reject':
        return AppColors.reject; // Merah
      default:
        return AppColors.primary;
    }
  }

  Widget _buildVotingUI() {
    final voteState = ref.watch(voteProvider);
    final isLoading = voteState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'SUARA PUBLIK KAWAL.Z',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.policy.pollingQuestion ?? 'Menurut kamu, apakah kebijakan ini sudah tepat?',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 16),
        ..._options.entries.map((entry) {
          final isSelected = _selectedOption == entry.key;
          final optionColor = _getOptionColor(entry.key);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: isLoading ? null : () => setState(() => _selectedOption = entry.key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? optionColor.withValues(alpha: 0.15) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? optionColor : AppColors.border,
                    width: 1.5, // Lebar tetap agar tidak ada pergeseran layout (flicker) saat diklik
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? optionColor : Colors.transparent,
                        border: isSelected
                            ? null
                            : Border.all(
                                color: AppColors.textTertiary,
                                width: 2,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? optionColor : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_selectedOption == null || isLoading) ? null : _submitVote,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.textTertiary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Kirim Suaraku', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultUI() {
    // Determine percentages (simulated with current counts + 1 for user's vote)
    int supportCount = widget.policy.supportCount + (_submittedOption == 'support' ? 1 : 0);
    int neutralCount = widget.policy.neutralCount + (_submittedOption == 'neutral' ? 1 : 0);
    int rejectCount = widget.policy.rejectCount + (_submittedOption == 'reject' ? 1 : 0);
    
    // Removed demo data fallback as we now have real user actions.
    final totalVotes = supportCount + neutralCount + rejectCount;
    final supportPercent = totalVotes == 0 ? 0 : (supportCount / totalVotes * 100).round();
    final neutralPercent = totalVotes == 0 ? 0 : (neutralCount / totalVotes * 100).round();
    final rejectPercent = totalVotes == 0 ? 0 : (rejectCount / totalVotes * 100).round();

    final userChoiceText = _submittedOption == 'support'
        ? 'Setuju'
        : _submittedOption == 'neutral'
            ? 'Netral'
            : 'Tolak';

    final userChoiceColor = _submittedOption != null ? _getOptionColor(_submittedOption!) : Colors.black;

    final progressBars = [
      {'label': 'Setuju', 'percent': supportPercent, 'color': AppColors.support},
      {'label': 'Tolak', 'percent': rejectPercent, 'color': AppColors.reject},
      {'label': 'Netral', 'percent': neutralPercent, 'color': AppColors.warning},
    ];

    // Sort descending by percentage
    progressBars.sort((a, b) => (b['percent'] as int).compareTo(a['percent'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: userChoiceColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: userChoiceColor, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suaramu sudah dihitung',
                      style: TextStyle(color: userChoiceColor, fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    Text(
                      userChoiceText.toUpperCase(),
                      style: TextStyle(
                        color: userChoiceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.brown.shade700, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '+20 XP',
                      style: TextStyle(color: Colors.brown.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Progress Bars
        ...progressBars.map((bar) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildProgressBar(
              bar['label'] as String,
              bar['percent'] as int,
              bar['color'] as Color,
            ),
          );
        }),
        
        const SizedBox(height: 24),
        // Footer Note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.info_outline, size: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${NumberFormat.decimalPattern('id_ID').format(totalVotes)} suara · Hasil polling ini murni mencerminkan opini pengguna Kawal.Z dan bukan representasi pandangan seluruh masyarakat Indonesia.',
                  style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildProgressBar(String label, int percentage, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            Text('$percentage%', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
