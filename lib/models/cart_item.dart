import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  final String restaurantId;
  final String restaurantName;
  int quantity;

  CartItem({
    required this.menuItem,
    required this.restaurantId,
    required this.restaurantName,
    this.quantity = 1,
  });

  double get subtotal => menuItem.price * quantity;
}
