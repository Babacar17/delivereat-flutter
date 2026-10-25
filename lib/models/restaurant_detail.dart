import 'restaurant.dart';
import 'menu_item.dart';

class RestaurantDetail {
  final Restaurant info;
  final List<MenuSection> menu;

  RestaurantDetail({required this.info, required this.menu});

  factory RestaurantDetail.fromJson(Map<String, dynamic> json) {
    final flatItems = (json['menu'] as List? ?? [])
        .map((e) => MenuItem.fromJson(e))
        .toList();
    return RestaurantDetail(
      info: Restaurant.fromJson(json),
      menu: MenuSection.groupBySection(flatItems),
    );
  }
}
