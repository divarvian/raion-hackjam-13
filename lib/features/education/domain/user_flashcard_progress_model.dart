class UserFlashcardProgress {
  final String id;
  final String userId;
  final String topicId;
  final int cardsCompleted;
  final bool isCompleted;
  final bool xpAwarded;
  final int lastCardIndex;

  UserFlashcardProgress({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.cardsCompleted,
    required this.isCompleted,
    required this.xpAwarded,
    required this.lastCardIndex,
  });

  factory UserFlashcardProgress.fromJson(Map<String, dynamic> json) {
    return UserFlashcardProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      topicId: json['topic_id'] as String,
      cardsCompleted: json['cards_completed'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      xpAwarded: json['xp_awarded'] as bool? ?? false,
      lastCardIndex: json['last_card_index'] as int? ?? 0,
    );
  }
}
