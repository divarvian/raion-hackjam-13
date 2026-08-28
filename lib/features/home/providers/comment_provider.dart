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

final commentListProvider = FutureProvider.family.autoDispose<List<CommentModel>, String>((ref, policyId) async {
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
});
