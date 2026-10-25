import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../services/order_service.dart';
import '../../providers/order_tracking_provider.dart';
import '../../models/order.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = OrderTrackingProvider(
          OrderService(ctx.read<ApiClient>()),
          orderId,
        );
        provider.start();
        return provider;
      },
      child: const _OrderTrackingBody(),
    );
  }
}

class _OrderTrackingBody extends StatelessWidget {
  const _OrderTrackingBody();

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.delivering,
    OrderStatus.delivered,
  ];

  String _statusLabel(OrderStatus status, String lang) {
    switch (status) {
      case OrderStatus.pending:
        return AppStrings.t('pending', lang);
      case OrderStatus.confirmed:
        return AppStrings.t('confirmed', lang);
      case OrderStatus.preparing:
        return AppStrings.t('preparing', lang);
      case OrderStatus.delivering:
        return AppStrings.t('delivering', lang);
      case OrderStatus.delivered:
        return AppStrings.t('delivered', lang);
      case OrderStatus.cancelled:
        return AppStrings.t('cancelled', lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderTrackingProvider>();
    final order = provider.order;
    final lang = context.watch<LocaleProvider>().languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('order_tracking', lang)),
        actions: [_ConnectionBadge(mode: provider.mode, lang: lang)],
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  order.restaurantName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text('#${order.id.substring(0, 8)}'),
                const SizedBox(height: 24),
                if (order.status == OrderStatus.cancelled)
                  Card(
                    color: isDark ? Colors.red[900] : const Color(0xFFFFE5E5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        AppStrings.t('order_cancelled_status', lang),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  )
                else
                  _StatusTimeline(order: order, steps: _steps, lang: lang),
                const SizedBox(height: 24),
                const Divider(),
                Text(
                  AppStrings.t('order_history', lang),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.statusHistory.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_statusLabel(e.status, lang)),
                        Text(
                          DateFormat('HH:mm:ss').format(e.timestamp.toLocal()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                ...order.items.map(
                  (item) => ListTile(
                    dense: true,
                    title: Text('${item.quantity}x ${item.name}'),
                    trailing: Text('${item.lineTotal.toStringAsFixed(0)} CFA'),
                  ),
                ),
                const Divider(),
                _priceRow(AppStrings.t('subtotal', lang), order.subtotal),
                _priceRow(
                  AppStrings.t('delivery_fee', lang),
                  order.deliveryFee,
                ),
                _priceRow(AppStrings.t('total', lang), order.total, bold: true),
                const SizedBox(height: 16),
                Text(
                  '${AppStrings.t('address_label', lang)} : ${order.deliveryAddress}',
                ),
                if (order.notes != null && order.notes!.isNotEmpty)
                  Text('${AppStrings.t('notes_label', lang)} : ${order.notes}'),
              ],
            ),
    );
  }

  Widget _priceRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value.toStringAsFixed(0)} CFA', style: style),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final Order order;
  final List<OrderStatus> steps;
  final String lang;
  const _StatusTimeline({
    required this.order,
    required this.steps,
    required this.lang,
  });

  String _statusLabel(OrderStatus status, String lang) {
    switch (status) {
      case OrderStatus.pending:
        return AppStrings.t('pending', lang);
      case OrderStatus.confirmed:
        return AppStrings.t('confirmed', lang);
      case OrderStatus.preparing:
        return AppStrings.t('preparing', lang);
      case OrderStatus.delivering:
        return AppStrings.t('delivering', lang);
      case OrderStatus.delivered:
        return AppStrings.t('delivered', lang);
      case OrderStatus.cancelled:
        return AppStrings.t('cancelled', lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexOf(order.status);
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[300]!;

    return Row(
      children: List.generate(steps.length, (index) {
        final reached = index <= currentIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 3,
                        color: index <= currentIndex
                            ? Colors.deepOrange
                            : inactiveColor,
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached ? Colors.deepOrange : inactiveColor,
                    ),
                    child: reached
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 3,
                        color: index < currentIndex
                            ? Colors.deepOrange
                            : inactiveColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _statusLabel(steps[index], lang),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final ConnectionMode mode;
  final String lang;
  const _ConnectionBadge({required this.mode, required this.lang});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (mode) {
      case ConnectionMode.live:
        label = AppStrings.t('live', lang);
        color = Colors.green;
        break;
      case ConnectionMode.connecting:
        label = AppStrings.t('connecting', lang);
        color = Colors.orange;
        break;
      case ConnectionMode.polling:
        label = AppStrings.t('updating', lang);
        color = Colors.blueGrey;
        break;
      case ConnectionMode.error:
        label = AppStrings.t('error', lang);
        color = Colors.red;
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
        backgroundColor: color,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
