import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../chatbot/presentation/widgets/chatbot_bottom_sheet.dart';
import '../../../chatbot/providers/chatbot_provider.dart';
import '../../../voting/presentation/widgets/inline_voting_widget.dart';
import '../../domain/policy_model.dart';
import '../../providers/policy_provider.dart';
import '../../providers/article_read_provider.dart';
import '../widgets/comment_section.dart';
import '../widgets/comment_input_bar.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String policyId;

  const ArticleDetailScreen({super.key, required this.policyId});

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _articleEndKey = GlobalKey();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_articleEndKey.currentContext != null) {
      final RenderBox box = _articleEndKey.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      // Jika widget sudah masuk ke layar (posisi Y kurang dari tinggi layar)
      if (position.dy < MediaQuery.of(context).size.height) {
        ref.read(articleReadProvider(widget.policyId).notifier).setReachedBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final policyAsync = ref.watch(policyDetailProvider(widget.policyId));
    ref.watch(chatbotProvider(widget.policyId));
    
    ref.listen<AsyncValue<ArticleReadState>>(
      articleReadProvider(widget.policyId),
      (previous, next) {
        // Hanya tampilkan snackbar jika sebelumnya `xpAwarded` adalah false (sedang dipantau)
        // dan sekarang menjadi true. Jika `previous` null, berarti ini inisialisasi awal.
        if (previous != null && previous.value?.xpAwarded == false && next.value?.xpAwarded == true) {
          SnackbarUtils.showSuccess(context, 'Hebat! Kamu dapat +10 XP dari membaca!');
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: CommentInputBar(policyId: widget.policyId),
      floatingActionButton: policyAsync.maybeWhen(
        data: (policy) => FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ChatbotBottomSheet(
                policyId: policy.id,
                articleContext: '${policy.title}\n${policy.fullContent}',
              ),
            );
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text('Tanya AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        orElse: () => null,
      ),
      body: policyAsync.when(
        data: (policy) => _buildBody(context, policy),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(policyDetailProvider(widget.policyId)),
        ),
      ),
    );
  }


  Widget _buildBody(BuildContext context, PolicyModel policy) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          clipBehavior: Clip.none,
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Gambar (Rendered First / Bottom Layer)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 300,
                    child: policy.thumbnailUrl != null
                        ? Image.network(
                            policy.thumbnailUrl!,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : Container(color: Colors.grey.shade300),
                  ),
                  
                  // 2. Konten (Rendered Second / Top Layer)
                  Padding(
                    padding: const EdgeInsets.only(top: 260.0), // Image height (300) - Overlap (40)
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Main Info Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  policy.title,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                                if (policy.subtitle != null && policy.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    policy.subtitle!,
                                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                                const SizedBox(height: 8), // Dipersempit jaraknya
                                if (policy.impactDescription != null && policy.impactDescription!.isNotEmpty) ...[
                                  Text(
                                    policy.impactDescription!,
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  children: [
                                    Text(
                                      policy.sourceName ?? 'Kompas.id',
                                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('·', style: TextStyle(color: AppColors.textTertiary)),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(policy.publishedAt),
                                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('·', style: TextStyle(color: AppColors.textTertiary)),
                                    ),
                                    Text(
                                      '${policy.estimatedReadMinutes} min',
                                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // AI Summary Box
                          if (policy.aiSummary.isNotEmpty) _buildAiSummaryBox(policy),

                          const SizedBox(height: 24),

                          // Konteks Lengkap
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Konteks Lengkap',
                                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  policy.fullContent,
                                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                                ),
                                const SizedBox(height: 32),
                                
                                // Reading Progress Widget (Target untuk setReachedBottom)
                                ReadingProgressWidget(
                                  key: _articleEndKey,
                                  policyId: policy.id,
                                ),
                                
                                const SizedBox(height: 24),
                                OutlinedButton(
                                  onPressed: () async {
                                    if (policy.sourceLink != null && policy.sourceLink!.isNotEmpty) {
                                      String link = policy.sourceLink!;
                                      if (!link.startsWith('http://') && !link.startsWith('https://')) {
                                        link = 'https://$link';
                                      }
                                      
                                      final url = Uri.parse(link);
                                      try {
                                        final launched = await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched && context.mounted) {
                                          SnackbarUtils.showError(context, 'Gagal membuka tautan di browser');
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          SnackbarUtils.showError(context, 'Terjadi kesalahan saat membuka tautan');
                                        }
                                      }
                                    } else {
                                      if (context.mounted) {
                                        SnackbarUtils.showError(context, 'Tautan sumber tidak tersedia');
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Baca artikel asli di ${policy.sourceName ?? "sumber"}'),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Voting Section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: InlineVotingWidget(policy: policy),
                          ),

                          const SizedBox(height: 24),

                          // Comments Section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: CommentSection(policyId: policy.id),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Floating Back Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSummaryBox(PolicyModel policy) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Ringkasan berbasis AI - Bukan sumber resmi',
                  style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: policy.aiSummary.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '0$index',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.content,
                              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ReadingProgressWidget extends ConsumerWidget {
  final String policyId;
  
  const ReadingProgressWidget({super.key, required this.policyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(articleReadProvider(policyId));
    
    return stateAsync.when(
      data: (state) {
        if (state.xpAwarded) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'XP berhasil didapatkan dari artikel ini',
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final int remainingSeconds = (30 - state.secondsPassed).clamp(0, 30);
        final double progress = state.secondsPassed / 30.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.hasReachedBottom 
                          ? 'Tunggu sebentar lagi untuk XP...' 
                          : 'Scroll sampai sini untuk XP',
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      remainingSeconds > 0
                          ? '$remainingSeconds detik lagi'
                          : 'Memproses XP...',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox(height: 60),
    );
  }
}
