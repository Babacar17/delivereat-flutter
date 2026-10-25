import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../core/token_storage.dart';
import '../models/order.dart';
import '../services/order_service.dart';

enum ConnectionMode { connecting, live, polling, error }

class OrderTrackingProvider extends ChangeNotifier {
  final OrderService _orderService;
  final String orderId;

  OrderTrackingProvider(this._orderService, this.orderId);

  Order? order;
  ConnectionMode mode = ConnectionMode.connecting;
  String? errorMessage;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pollingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  Future<void> start() async {
    try {
      order = await _orderService.getOrder(orderId);
      notifyListeners();
    } catch (_) {
      // On tente quand même le WebSocket / polling même si le
      // chargement initial échoue (ex: coupure réseau temporaire).
    }
    await _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    _subscription?.cancel();
    await _channel?.sink.close();

    try {
      // S'assure d'avoir un token frais : cet appel déclenche le
      // refresh automatique de l'intercepteur dio si nécessaire.
      order = await _orderService.getOrder(orderId);
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        _fallbackToPolling();
        return;
      }

      final uri = Uri.parse('${ApiConstants.wsUrl}/ws?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );

      mode = ConnectionMode.connecting;
      notifyListeners();
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'];

      if (type == 'hello') {
        mode = ConnectionMode.live;
        _reconnectAttempts = 0;
        _stopPolling();
        notifyListeners();
      } else if (type == 'order_update') {
        final updated = data['order'];
        if (updated != null) {
          order = Order.fromJson(updated);
          notifyListeners();
        }
      }
    } catch (_) {
      // message mal formé -> ignoré, on ne casse pas la connexion
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    if (order?.status == OrderStatus.delivered ||
        order?.status == OrderStatus.cancelled) {
      // Commande terminée : pas besoin de se reconnecter
      return;
    }

    _reconnectAttempts += 1;

    if (_reconnectAttempts <= 3) {
      // Reconnexion avec backoff court, en récupérant un token frais
      mode = ConnectionMode.connecting;
      notifyListeners();
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(
        Duration(seconds: _reconnectAttempts * 2),
        _connectWebSocket,
      );
    } else {
      _fallbackToPolling();
    }
  }

  void _fallbackToPolling() {
    if (_disposed) return;
    mode = ConnectionMode.polling;
    notifyListeners();
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final updated = await _orderService.getOrder(orderId);
        order = updated;
        notifyListeners();

        if (updated.status == OrderStatus.delivered ||
            updated.status == OrderStatus.cancelled) {
          _stopPolling();
        } else {
          // On retente périodiquement le WebSocket en tâche de fond
          _reconnectAttempts = 0;
          _connectWebSocket();
        }
      } catch (_) {
        // on continue le polling malgré une erreur ponctuelle
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> refreshNow() async {
    try {
      order = await _orderService.getOrder(orderId);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    _pollingTimer?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}
