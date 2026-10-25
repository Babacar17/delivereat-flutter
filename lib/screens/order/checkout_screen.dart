import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/app_strings.dart';
import '../../services/order_service.dart';
import '../../core/errors.dart';
import '../../core/api_client.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _validateAddress(String? value, String lang) {
    if (value == null || value.trim().length < 5) {
      return AppStrings.t('invalid_address', lang);
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    if (cart.isEmpty || cart.restaurantId == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final orderService = OrderService(context.read<ApiClient>());
      final order = await orderService.createOrder(
        restaurantId: cart.restaurantId!,
        items: cart.items,
        deliveryAddress: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      cart.clear();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.id),
        ),
      );
    } on AppError catch (e) {
      // Gère notamment RESTAURANT_CLOSED sans planter l'écran
      setState(() => _errorMessage = e.message);
    } catch (_) {
      final lang = context.read<LocaleProvider>().languageCode;
      setState(() => _errorMessage = AppStrings.t('unknown_error', lang));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final lang = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('checkout', lang))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                cart.restaurantName ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t('delivery_address', lang),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => _validateAddress(v, lang),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t('notes_optional', lang),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const Divider(),
              ...cart.items.map(
                (item) => ListTile(
                  dense: true,
                  title: Text('${item.quantity}x ${item.menuItem.name}'),
                  trailing: Text('${item.subtotal.toStringAsFixed(0)} CFA'),
                ),
              ),
              const Divider(),
              _priceRow(AppStrings.t('subtotal', lang), cart.subtotal),
              _priceRow(AppStrings.t('delivery_fee', lang), cart.deliveryFee),
              _priceRow(AppStrings.t('total', lang), cart.total, bold: true),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(AppStrings.t('confirm_order', lang)),
                    ),
            ],
          ),
        ),
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
