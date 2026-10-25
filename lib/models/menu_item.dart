import '../core/constants.dart';

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String section;
  final String imageUrl;
  final bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.section,
    required this.imageUrl,
    required this.available,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      section: json['section'] ?? 'Autres',
      imageUrl: _resolveImageUrl(json['imageUrl']),
      available: json['available'] ?? true,
    );
  }

  static String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }
}

class MenuSection {
  final String title;
  final List<MenuItem> items;

  MenuSection({required this.title, required this.items});

  /// Regroupe une liste plate d'articles par leur champ `section`,
  /// en conservant l'ordre d'apparition des sections dans le JSON.
  static List<MenuSection> groupBySection(List<MenuItem> items) {
    final Map<String, List<MenuItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }
    return grouped.entries
        .map((e) => MenuSection(title: e.key, items: e.value))
        .toList();
  }
}
