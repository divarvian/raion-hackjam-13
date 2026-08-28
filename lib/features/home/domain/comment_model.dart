class CommentModel {
  final String id;
  final String userId;
  final String policyId;
  final String? parentId;
  final String content;
  final int likes;
  final DateTime createdAt;
  
  // From joined profiles table
  final String userFullName;
  
  // Local state for UI
  final bool hasLiked;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.userId,
    required this.policyId,
    this.parentId,
    required this.content,
    required this.likes,
    required this.createdAt,
    required this.userFullName,
    this.hasLiked = false,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json, {bool hasLiked = false}) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] as String? ?? 'User';

    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      policyId: json['policy_id'] as String,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      likes: json['likes_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      userFullName: fullName,
      hasLiked: hasLiked,
      replies: [],
    );
  }

  CommentModel copyWith({
    String? id,
    String? userId,
    String? policyId,
    String? parentId,
    String? content,
    int? likes,
    DateTime? createdAt,
    String? userFullName,
    bool? hasLiked,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      policyId: policyId ?? this.policyId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      userFullName: userFullName ?? this.userFullName,
      hasLiked: hasLiked ?? this.hasLiked,
      replies: replies ?? this.replies,
    );
  }
}
