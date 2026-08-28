import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../data/comment_repository.dart';
import '../../providers/comment_provider.dart';

class CommentInputBar extends ConsumerStatefulWidget {
  final String policyId;

  const CommentInputBar({super.key, required this.policyId});

  @override
  ConsumerState<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends ConsumerState<CommentInputBar> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(commentRepositoryProvider);
      final replyState = ref.read(replyStateProvider);
      
      await repo.addComment(
        policyId: widget.policyId,
        content: text,
        parentId: replyState?.commentId,
      );
      
      _commentController.clear();
      _focusNode.unfocus();
      ref.read(replyStateProvider.notifier).state = null;
      ref.invalidate(commentListProvider(widget.policyId));
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final fullName = profileAsync.value?['full_name'] as String? ?? 'User';
    final initials = fullName.length >= 2 ? fullName.substring(0, 2).toUpperCase() : fullName.toUpperCase();
    
    // Listen to reply state to request focus when user clicks "Balas"
    ref.listen<ReplyState?>(replyStateProvider, (previous, next) {
      if (next != null && (previous?.commentId != next.commentId)) {
        _focusNode.requestFocus();
      } else if (next == null) {
        _focusNode.unfocus();
      }
    });
    
    final replyState = ref.watch(replyStateProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 12.0,
        bottom: MediaQuery.of(context).padding.bottom + 12.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyState != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text('Membalas ', style: AppTextStyles.caption),
                  Text(replyState.username, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  InkWell(
                    onTap: () => ref.read(replyStateProvider.notifier).state = null,
                    child: const Icon(Icons.close, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    enabled: !_isSubmitting,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                    decoration: InputDecoration(
                      hintText: replyState != null 
                          ? 'Balas komentar ${replyState.username}...' 
                          : 'Tambahkan komentar...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _isSubmitting
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16, height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: AppColors.primary, size: 20),
                            onPressed: _submitComment,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
