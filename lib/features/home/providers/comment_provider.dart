import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/comment_repository.dart';
import '../domain/comment_model.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});

class ReplyState {
  final String commentId;
  final String username;
  ReplyState({required this.commentId, required this.username});
}

final replyStateProvider = StateProvider.autoDispose<ReplyState?>((ref) => null);

class CommentListNotifier extends AutoDisposeFamilyAsyncNotifier<List<CommentModel>, String> {
  @override
  FutureOr<List<CommentModel>> build(String arg) async {
    return _fetchComments(arg);
  }

  Future<List<CommentModel>> _fetchComments(String policyId) async {
    final repo = ref.watch(commentRepositoryProvider);
    
    // Fetch comments and user likes in parallel
    final results = await Future.wait([
      repo.fetchComments(policyId),
      repo.fetchUserLikes(policyId),
    ]);

    final commentsData = results[0];
    final userLikesData = results[1];

    // Extract liked comment IDs
    final Set<String> likedCommentIds = userLikesData.map((e) => e['comment_id'] as String).toSet();

    // Map to Model
    final List<CommentModel> allComments = commentsData.map((json) {
      final commentId = json['id'] as String;
      return CommentModel.fromJson(json, hasLiked: likedCommentIds.contains(commentId));
    }).toList();

    // Separate parents and replies
    final Map<String, List<CommentModel>> repliesMap = {};
    final List<CommentModel> parentComments = [];

    for (var comment in allComments) {
      if (comment.parentId == null) {
        parentComments.add(comment);
      } else {
        if (!repliesMap.containsKey(comment.parentId)) {
          repliesMap[comment.parentId!] = [];
        }
        repliesMap[comment.parentId!]!.add(comment);
      }
    }

    // Attach replies to parents
    final List<CommentModel> threadedComments = parentComments.map((parent) {
      return parent.copyWith(replies: repliesMap[parent.id] ?? []);
    }).toList();

    return threadedComments;
  }

  Future<void> toggleLike(String commentId, bool currentHasLiked) async {
    final previousState = state;
    
    // 1. Optimistic Update (Manipulasi UI lokal secara instan)
    state = state.whenData((comments) {
      return comments.map((parent) {
        if (parent.id == commentId) {
          return parent.copyWith(
            hasLiked: !currentHasLiked,
            likes: parent.likes + (currentHasLiked ? -1 : 1),
          );
        }
        
        // Cek apakah yang dilike adalah reply-nya
        final updatedReplies = parent.replies.map((reply) {
          if (reply.id == commentId) {
            return reply.copyWith(
              hasLiked: !currentHasLiked,
              likes: reply.likes + (currentHasLiked ? -1 : 1),
            );
          }
          return reply;
        }).toList();
        
        return parent.copyWith(replies: updatedReplies);
      }).toList();
    });

    try {
      // 2. Eksekusi ke Database Supabase di background
      final repo = ref.read(commentRepositoryProvider);
      await repo.toggleLike(commentId, currentHasLiked);
    } catch (e) {
      // 3. Rollback jika database error
      state = previousState;
      rethrow; // Biarkan UI menangkap error
    }
  }
}

final commentListProvider = AsyncNotifierProvider.autoDispose.family<CommentListNotifier, List<CommentModel>, String>(
  CommentListNotifier.new,
);
