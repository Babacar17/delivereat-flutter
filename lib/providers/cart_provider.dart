import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;
  double _deliveryFee = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  double get deliveryFee => _items.isEmpty ? 0 : _deliveryFee;

  double get total => subtotal + deliveryFee;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Retourne true si l'ajout a été fait directement.
  /// Retourne false si un conflit de restaurant a été détecté
  /// (l'appelant doit alors afficher la boîte de dialogue de confirmation).
  bool addItem(
    MenuItem menuItem,
    String restaurantId,
    String restaurantName,
    double deliveryFee,
  ) {
    if (_restaurantId != null && _restaurantId != restaurantId) {
      return false; // conflit -> géré par l'UI
    }
    _restaurantId = restaurantId;
    _restaurantName = restaurantName;
    _deliveryFee = deliveryFee;

    final existingIndex = _items.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(
        CartItem(
          menuItem: menuItem,
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  /// Vide le panier puis ajoute le nouvel article -> utilisé après
  /// confirmation de la boîte de dialogue "vider le panier".
  void replaceCartWithItem(
    MenuItem menuItem,
    String restaurantId,
    String restaurantName,
    double deliveryFee,
  ) {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    addItem(menuItem, restaurantId, restaurantName, deliveryFee);
  }

  void incrementQuantity(String menuItemId) {
    final item = _items.firstWhere((i) => i.menuItem.id == menuItemId);
    item.quantity += 1;
    notifyListeners();
  }

  void decrementQuantity(String menuItemId) {
    final index = _items.indexWhere((i) => i.menuItem.id == menuItemId);
    if (index < 0) return;
    if (_items[index].quantity > 1) {
      _items[index].quantity -= 1;
    } else {
      _items.removeAt(index);
    }
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.removeWhere((i) => i.menuItem.id == menuItemId);
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    notifyListeners();
  }
}
