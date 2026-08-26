class FlashcardTopic {
  final String id;
  final String categoryId;
  final String title;
  final String? subtitle;
  final String iconName;
  final int totalCards;
  final int orderIndex;
  final bool isLocked;
  final int xpReward;

  FlashcardTopic({
    required this.id,
    required this.categoryId,
    required this.title,
    this.subtitle,
    required this.iconName,
    required this.totalCards,
    required this.orderIndex,
    required this.isLocked,
    required this.xpReward,
  });

  factory FlashcardTopic.fromJson(Map<String, dynamic> json) {
    return FlashcardTopic(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      iconName: json['icon_name'] as String? ?? 'article',
      totalCards: json['total_cards'] as int? ?? 0,
      orderIndex: json['order_index'] as int? ?? 0,
      isLocked: json['is_locked'] as bool? ?? false,
      xpReward: json['xp_reward'] as int? ?? 15,
    );
  }
}
