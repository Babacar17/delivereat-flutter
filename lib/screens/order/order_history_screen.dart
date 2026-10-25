import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_history_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/app_strings.dart';
import '../../models/order.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderHistoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderHistoryProvider>();
    final lang = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('my_orders', lang))),
      body: Column(
        children: [
          _buildFilterBar(context, provider, lang),
          Expanded(child: _buildBody(context, provider, lang)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    OrderHistoryProvider provider,
    String lang,
  ) {
    final options = <String, OrderStatus?>{
      AppStrings.t('all', lang): null,
      AppStrings.t('pending', lang): OrderStatus.pending,
      AppStrings.t('confirmed', lang): OrderStatus.confirmed,
      AppStrings.t('preparing', lang): OrderStatus.preparing,
      AppStrings.t('delivering', lang): OrderStatus.delivering,
      AppStrings.t('delivered', lang): OrderStatus.delivered,
      AppStrings.t('cancelled', lang): OrderStatus.cancelled,
    };

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: options.entries.map((entry) {
          final selected = provider.filterStatus == entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.key),
              selected: selected,
              onSelected: (_) =>
                  context.read<OrderHistoryProvider>().setFilter(entry.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderHistoryProvider provider,
    String lang,
  ) {
    switch (provider.state) {
      case HistoryState.loading:
        return const Center(child: CircularProgressIndicator());

      case HistoryState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage ?? AppStrings.t('error', lang)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.load(),
                child: Text(AppStrings.t('retry', lang)),
              ),
            ],
          ),
        );

      case HistoryState.empty:
        return Center(child: Text(AppStrings.t('empty_orders', lang)));

      case HistoryState.loaded:
        return ListView.builder(
          itemCount: provider.orders.length,
          itemBuilder: (context, index) =>
              _OrderCard(order: provider.orders[index], lang: lang),
        );
    }
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final String lang;
  const _OrderCard({required this.order, required this.lang});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
      case OrderStatus.delivering:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

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

  Future<void> _handleCancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('cancel_order_title', lang)),
        content: Text(AppStrings.t('cancel_order_confirm', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t('no', lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.t('yes_cancel', lang)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final provider = context.read<OrderHistoryProvider>();
    final success = await provider.cancelOrder(order.id);

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('order_cancelled', lang))),
      );
    } else if (provider.cancelError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.cancelError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: order.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(order.createdAt.toLocal()),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      label: Text(
                        _statusLabel(order.status, lang),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: _statusColor(order.status),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${order.total.toStringAsFixed(0)} CFA'),
                  if (order.status == OrderStatus.pending) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _handleCancel(context),
                      child: Text(
                        AppStrings.t('cancel', lang),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
