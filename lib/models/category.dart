class Category {
  final String id;
  final String name;
  final String emoji;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
