import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../models/order.dart';
import '../services/order_service.dart';

enum HistoryState { loading, loaded, empty, error }

class OrderHistoryProvider extends ChangeNotifier {
  final OrderService _service;
  OrderHistoryProvider(this._service);

  List<Order> orders = [];
  HistoryState state = HistoryState.loading;
  String? errorMessage;
  OrderStatus? filterStatus;

  String? _cancelError;
  String? get cancelError => _cancelError;

  Future<void> load() async {
    state = HistoryState.loading;
    notifyListeners();
    try {
      orders = await _service.getOrders(
        status: filterStatus == null ? null : _statusToString(filterStatus!),
      );
      state = orders.isEmpty ? HistoryState.empty : HistoryState.loaded;
    } on AppError catch (e) {
      errorMessage = e.message;
      state = HistoryState.error;
    } catch (_) {
      errorMessage = 'Une erreur est survenue';
      state = HistoryState.error;
    }
    notifyListeners();
  }

  void setFilter(OrderStatus? status) {
    filterStatus = status;
    load();
  }

  Future<bool> cancelOrder(String orderId) async {
    _cancelError = null;
    try {
      await _service.cancelOrder(orderId);
      await load(); // recharge la liste pour refléter le nouveau statut
      return true;
    } on AppError catch (e) {
      // Gère notamment 422 CANNOT_CANCEL sans faire planter l'écran
      _cancelError = e.message;
      notifyListeners();
      return false;
    }
  }

  String _statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.delivering:
        return 'delivering';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}
