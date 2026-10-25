enum OrderStatus {
  pending,
  confirmed,
  preparing,
  delivering,
  delivered,
  cancelled,
}

OrderStatus orderStatusFromString(String value) {
  switch (value) {
    case 'pending':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'delivering':
      return OrderStatus.delivering;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'En attente';
    case OrderStatus.confirmed:
      return 'Confirmée';
    case OrderStatus.preparing:
      return 'En préparation';
    case OrderStatus.delivering:
      return 'En livraison';
    case OrderStatus.delivered:
      return 'Livrée';
    case OrderStatus.cancelled:
      return 'Annulée';
  }
}

class OrderStatusEvent {
  final OrderStatus status;
  final DateTime timestamp;

  OrderStatusEvent({required this.status, required this.timestamp});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: orderStatusFromString(json['status'] ?? ''),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: (json['menuItemId'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      lineTotal: (json['lineTotal'] ?? 0).toDouble(),
    );
  }
}

class Order {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final List<OrderStatusEvent> statusHistory;

  Order({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    this.notes,
    required this.createdAt,
    this.statusHistory = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      restaurantId: (json['restaurantId'] ?? '').toString(),
      restaurantName: json['restaurantName'] ?? '',
      status: orderStatusFromString(json['status'] ?? ''),
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      deliveryAddress: json['deliveryAddress'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      statusHistory: (json['statusHistory'] as List? ?? [])
          .map((e) => OrderStatusEvent.fromJson(e))
          .toList(),
    );
  }
}
