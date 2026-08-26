class FlashcardCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String iconName;
  final String colorHex;
  final int orderIndex;

  FlashcardCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.iconName,
    required this.colorHex,
    required this.orderIndex,
  });

  factory FlashcardCategory.fromJson(Map<String, dynamic> json) {
    return FlashcardCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String? ?? 'book',
      colorHex: json['color_hex'] as String? ?? '#4CAF50',
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }
}
