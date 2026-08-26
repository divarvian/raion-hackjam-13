class Flashcard {
  final String id;
  final String topicId;
  final String cardType; // 'info', 'question', 'fun_fact'
  final String? title;
  final String contentText;
  final Map<String, dynamic>? extraContent;
  final String? illustrationUrl;
  final int orderIndex;

  Flashcard({
    required this.id,
    required this.topicId,
    required this.cardType,
    this.title,
    required this.contentText,
    this.extraContent,
    this.illustrationUrl,
    required this.orderIndex,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      cardType: json['card_type'] as String? ?? 'info',
      title: json['title'] as String?,
      contentText: json['content_text'] as String,
      extraContent: json['extra_content'] as Map<String, dynamic>?,
      illustrationUrl: json['illustration_url'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }
}
