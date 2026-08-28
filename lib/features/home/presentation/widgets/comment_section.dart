import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../domain/comment_model.dart';
import '../../providers/comment_provider.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String policyId;

  const CommentSection({super.key, required this.policyId});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  void _toggleLike(CommentModel comment) async {
    try {
      final repo = ref.read(commentRepositoryProvider);
      // Optimistic invalidation
      await repo.toggleLike(comment.id, comment.hasLiked);
      ref.invalidate(commentListProvider(widget.policyId));
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    }
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}th lalu';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}bln lalu';
    if (diff.inDays > 0) return '${diff.inDays}h lalu';
    if (diff.inHours > 0) return '${diff.inHours}j lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final commentsAsync = ref.watch(commentListProvider(widget.policyId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Komentar', style: AppTextStyles.titleLarge),
            const Spacer(),
            commentsAsync.maybeWhen(
              data: (comments) {
                // Count all comments including replies
                int total = comments.length;
                for (var c in comments) {
                  total += c.replies.length;
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$total',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                  ),
                );
              },
              orElse: () => const SizedBox(),
            ),
          ],
        ),
        
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text('Belum ada komentar. Jadilah yang pertama!', style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCommentItem(comment, isReply: false, hasReplies: comment.replies.isNotEmpty),
                      if (comment.replies.isNotEmpty) ...[
                        ...comment.replies.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          final reply = entry.value;
                          return _buildCommentItem(
                            reply, 
                            isReply: true, 
                            isLastReply: idx == comment.replies.length - 1,
                          );
                        }).toList(),
                      ]
                    ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, s) => Center(child: Text('Gagal memuat komentar', style: TextStyle(color: Colors.red))),
        ),
      ],
    );
  }

  Widget _buildCommentItem(CommentModel comment, {
    required bool isReply, 
    bool isLastReply = true, 
    bool hasReplies = false,
  }) {
    final initials = comment.userFullName.length >= 2 
        ? comment.userFullName.substring(0, 2).toUpperCase() 
        : comment.userFullName.toUpperCase();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isReply)
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (hasReplies)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            )
          else ...[
            SizedBox(
              width: 32, 
              child: Stack(
                children: [
                  Positioned(
                    left: 15, 
                    top: 0, 
                    width: 17, 
                    height: 13, 
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(width: 2, color: Colors.grey.shade300),
                          bottom: BorderSide(width: 2, color: Colors.grey.shade300),
                        ),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8)),
                      ),
                    ),
                  ),
                  if (!isLastReply)
                    Positioned(
                      left: 15,
                      top: 13, 
                      bottom: 0, 
                      child: Container(
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(comment.userFullName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(_formatTimeAgo(comment.createdAt), style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleLike(comment),
                        child: Icon(
                          comment.hasLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16, 
                          color: comment.hasLiked ? Colors.red : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${comment.likes}', style: AppTextStyles.caption.copyWith(
                        color: comment.hasLiked ? Colors.red : null,
                        fontWeight: comment.hasLiked ? FontWeight.bold : null,
                      )),
                      
                      if (!isReply) ...[
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            ref.read(replyStateProvider.notifier).state = 
                                ReplyState(commentId: comment.id, username: comment.userFullName);
                          },
                          child: Text('Balas', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
