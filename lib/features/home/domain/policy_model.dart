class PolicyModel {
  final String id;
  final String title;
  final String? subtitle;
  final String category;
  final List<String> aiSummary;
  final String fullContent;
  final String? thumbnailUrl;
  final String? sourceName;
  final String? sourceLink;
  final int estimatedReadMinutes;
  final int supportCount;
  final int rejectCount;
  final int totalVotes;
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
    required this.supportCount,
    required this.rejectCount,
    required this.totalVotes,
    required this.isTrending,
    this.trendingRank,
    this.impactDescription,
    required this.publishedAt,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    // Handle Supabase JSONB yang kembalinya sebagai List<dynamic>
    List<String> parsedSummary = [];
    if (json['ai_summary'] != null) {
      if (json['ai_summary'] is List) {
        parsedSummary = (json['ai_summary'] as List).map((e) => e.toString()).toList();
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
      supportCount: json['support_count'] as int? ?? 0,
      rejectCount: json['reject_count'] as int? ?? 0,
      totalVotes: json['total_votes'] as int? ?? 0,
      isTrending: json['is_trending'] as bool? ?? false,
      trendingRank: json['trending_rank'] as int?,
      impactDescription: json['impact_description'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }
}
