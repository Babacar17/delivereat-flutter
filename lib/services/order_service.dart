import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/errors.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  final ApiClient _client;
  OrderService(this._client);

  Future<Order> createOrder({
    required String restaurantId,
    required List<CartItem> items,
    required String deliveryAddress,
    String? notes,
  }) async {
    try {
      final res = await _client.dio.post(
        '/orders',
        data: {
          'restaurantId': restaurantId,
          'items': items
              .map((i) => {'menuItemId': i.menuItem.id, 'quantity': i.quantity})
              .toList(),
          'deliveryAddress': deliveryAddress,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return Order.fromJson(res.data);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<Order> getOrder(String id) async {
    try {
      final res = await _client.dio.get('/orders/$id');
      return Order.fromJson(res.data);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<List<Order>> getOrders({String? status}) async {
    try {
      final res = await _client.dio.get(
        '/orders',
        queryParameters: {if (status != null) 'status': status},
      );
      final list = res.data['data'] as List? ?? res.data as List;
      return list.map((e) => Order.fromJson(e)).toList();
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<void> cancelOrder(String id) async {
    try {
      await _client.dio.post('/orders/$id/cancel');
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }
}
