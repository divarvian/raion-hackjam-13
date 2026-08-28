class AiSummaryItem {
  final String title;
  final String content;

  AiSummaryItem({required this.title, required this.content});

  factory AiSummaryItem.fromJson(Map<String, dynamic> json) {
    return AiSummaryItem(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class PolicyModel {
  final String id;
  final String title;
  final String? subtitle;
  final String category;
  final List<AiSummaryItem> aiSummary;
  final String fullContent;
  final String? thumbnailUrl;
  final String? sourceName;
  final String? sourceLink;
  final int estimatedReadMinutes;
  
  final String? pollingQuestion;
  final int supportCount;
  final int neutralCount;
  final int rejectCount;
  final int totalVotes;
  final int commentsCount;
  
  final bool isTrending;
  final int? trendingRank;
  final String? impactDescription;
  final DateTime publishedAt;

  PolicyModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.category,
    required this.aiSummary,
    required this.fullContent,
    this.thumbnailUrl,
    this.sourceName,
    this.sourceLink,
    required this.estimatedReadMinutes,
    this.pollingQuestion,
    required this.supportCount,
    required this.neutralCount,
    required this.rejectCount,
    required this.totalVotes,
    required this.commentsCount,
    required this.isTrending,
    this.trendingRank,
    this.impactDescription,
    required this.publishedAt,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    List<AiSummaryItem> parsedSummary = [];
    if (json['ai_summary'] != null) {
      if (json['ai_summary'] is List) {
        parsedSummary = (json['ai_summary'] as List).map((e) {
          if (e is Map<String, dynamic>) {
            return AiSummaryItem.fromJson(e);
          } else if (e is String) {
            // Fallback for old data
            return AiSummaryItem(title: "Ringkasan", content: e);
          }
          return AiSummaryItem(title: "", content: "");
        }).toList();
      }
    }

    return PolicyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      category: json['category'] as String? ?? 'Umum',
      aiSummary: parsedSummary,
      fullContent: json['full_content'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      sourceName: json['source_name'] as String?,
      sourceLink: json['source_link'] as String?,
      estimatedReadMinutes: json['estimated_read_minutes'] as int? ?? 5,
      pollingQuestion: json['polling_question'] as String?,
      supportCount: json['support_count'] as int? ?? 0,
      neutralCount: json['neutral_count'] as int? ?? 0,
      rejectCount: json['reject_count'] as int? ?? 0,
      totalVotes: json['total_votes'] as int? ?? 0,
      commentsCount: _parseCommentsCount(json['comments']),
      isTrending: json['is_trending'] as bool? ?? false,
      trendingRank: json['trending_rank'] as int?,
      impactDescription: json['impact_description'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }

  static int _parseCommentsCount(dynamic commentsJson) {
    try {
      if (commentsJson != null && commentsJson is List && commentsJson.isNotEmpty) {
        final first = commentsJson.first;
        if (first is Map && first['count'] != null) {
          return int.tryParse(first['count'].toString()) ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }
}
