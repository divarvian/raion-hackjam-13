import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../home/domain/policy_model.dart';
import '../../../home/providers/policy_provider.dart';
import '../../providers/vote_provider.dart';

class VoteScreen extends ConsumerStatefulWidget {
  final String policyId;

  const VoteScreen({super.key, required this.policyId});

  @override
  ConsumerState<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends ConsumerState<VoteScreen> {
  late ConfettiController _confettiController;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleVote(String voteType) {
    ref.read(voteProvider.notifier).castVote(
      policyId: widget.policyId, 
      voteType: voteType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final policyAsync = ref.watch(policyDetailProvider(widget.policyId));
    final voteState = ref.watch(voteProvider);

    // Watch for success
    ref.listen(voteProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        final result = next.value!;
        if (result['success'] == true) {
          setState(() {
            _hasVoted = true;
          });
          _confettiController.play();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Gagal vote')),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: policyAsync.when(
              data: (policy) {
                if (_hasVoted && voteState.value != null) {
                  return _buildResult(voteState.value!);
                }
                return _buildVoteCard(policy, voteState is AsyncLoading);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24.0),
                child: AppShimmerList(itemCount: 1, itemHeight: 400),
              ),
              error: (error, stack) => AppErrorWidget(
                error: error,
                onRetry: () => ref.invalidate(policyDetailProvider(widget.policyId)),
              ),
            ),
          ),
          
          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppColors.primary, AppColors.support, AppColors.accent],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteCard(PolicyModel policy, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Bagaimana pendapatmu\ntentang isu ini?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSizes.p32),
          
          Container(
            padding: const EdgeInsets.all(AppSizes.p24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.r24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  policy.category.toUpperCase(),
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  policy.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 32),
                
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reject Button
                      _buildVoteButton(
                        icon: Icons.thumb_down_rounded,
                        label: 'TOLAK',
                        color: AppColors.reject,
                        onTap: () => _handleVote('reject'),
                      ),
                      
                      // Support Button
                      _buildVoteButton(
                        icon: Icons.thumb_up_rounded,
                        label: 'DUKUNG',
                        color: AppColors.support,
                        onTap: () => _handleVote('support'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> result) {
    final xpAwarded = result['xp_awarded'];
    final supportPercent = result['support_percentage'];
    final rejectPercent = result['reject_percentage'];
    
    return Padding(
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.support, size: 80),
          const SizedBox(height: 24),
          Text(
            'Suaramu Telah Tercatat!',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '+$xpAwarded XP ditambahkan ke profilmu',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.amber),
          ),
          const SizedBox(height: 48),
          
          // Result Bar
          Text(
            'Sentimen Saat Ini:',
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: supportPercent,
                child: Container(
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.support,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                  ),
                  child: Center(
                    child: Text(
                      '$supportPercent%',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: rejectPercent,
                child: Container(
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.reject,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                  ),
                  child: Center(
                    child: Text(
                      '$rejectPercent%',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dukung', style: AppTextStyles.caption.copyWith(color: AppColors.support)),
              Text('Tolak', style: AppTextStyles.caption.copyWith(color: AppColors.reject)),
            ],
          ),
          
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.bgDark,
            ),
            child: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
  }
}
