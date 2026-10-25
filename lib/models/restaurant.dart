import '../core/constants.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final double rating;
  final int ratingCount;
  final double deliveryFee;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final bool isOpen;
  final String address;
  final bool isFavorite;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.ratingCount,
    required this.deliveryFee,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.isOpen,
    required this.address,
    this.isFavorite = false,
  });
  Restaurant copyWith({bool? isFavorite}) {
    return Restaurant(
      id: id,
      name: name,
      description: description,
      category: category,
      imageUrl: imageUrl,
      rating: rating,
      ratingCount: ratingCount,
      deliveryFee: deliveryFee,
      deliveryTimeMin: deliveryTimeMin,
      deliveryTimeMax: deliveryTimeMax,
      isOpen: isOpen,
      address: address,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Affichage pratique pour l'UI : "25-40 min"
  String get deliveryTimeLabel => '$deliveryTimeMin-$deliveryTimeMax min';

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: _resolveImageUrl(json['imageUrl']),
      rating: (json['rating'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      deliveryTimeMin: json['deliveryTimeMin'] ?? 0,
      deliveryTimeMax: json['deliveryTimeMax'] ?? 0,
      isOpen: json['isOpen'] ?? true,
      address: json['address'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  static String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }
}
