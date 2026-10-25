import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_detail_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/app_strings.dart';
import '../../models/menu_item.dart';
import '../../models/review.dart';
import '../cart/cart_screen.dart';
import 'widgets/review_form.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantDetailProvider>().load(widget.restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantDetailProvider>();
    final lang = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      body: _buildBody(provider, lang),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
            icon: const Icon(Icons.shopping_cart),
            label: Text(
              '${cart.totalItemCount} · ${cart.total.toStringAsFixed(0)} CFA',
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(RestaurantDetailProvider provider, String lang) {
    switch (provider.state) {
      case DetailState.loading:
        return const Center(child: CircularProgressIndicator());

      case DetailState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage ?? AppStrings.t('error', lang)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.load(widget.restaurantId),
                child: Text(AppStrings.t('retry', lang)),
              ),
            ],
          ),
        );

      case DetailState.loaded:
        final detail = provider.detail!;
        final restaurant = detail.info;
        final fallbackColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.grey[300]!;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'restaurant-image-${restaurant.id}',
                  child: Image.network(
                    restaurant.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: fallbackColor),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    restaurant.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: restaurant.isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () =>
                      context.read<RestaurantDetailProvider>().toggleFavorite(),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(restaurant.description),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '⭐ ${restaurant.rating.toStringAsFixed(1)} (${restaurant.ratingCount})',
                        ),
                        const SizedBox(width: 12),
                        Text(restaurant.deliveryTimeLabel),
                        const SizedBox(width: 12),
                        Text(
                          '${restaurant.deliveryFee.toStringAsFixed(0)} CFA',
                        ),
                      ],
                    ),
                    if (!restaurant.isOpen) ...[
                      const SizedBox(height: 8),
                      Chip(label: Text(AppStrings.t('closed_badge', lang))),
                    ],
                  ],
                ),
              ),
            ),
            for (final section in detail.menu) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MenuItemTile(
                    item: section.items[index],
                    restaurantId: restaurant.id,
                    restaurantName: restaurant.name,
                    deliveryFee: restaurant.deliveryFee,
                  ),
                  childCount: section.items.length,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  '${AppStrings.t('reviews', lang)} (${provider.reviews.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverToBoxAdapter(child: ReviewForm(restaurantId: restaurant.id)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _ReviewTile(review: provider.reviews[index]),
                childCount: provider.reviews.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
    }
  }
}

class _MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final String restaurantId;
  final String restaurantName;
  final double deliveryFee;

  const _MenuItemTile({
    required this.item,
    required this.restaurantId,
    required this.restaurantName,
    required this.deliveryFee,
  });

  Future<void> _handleAdd(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final lang = context.read<LocaleProvider>().languageCode;
    final added = cart.addItem(item, restaurantId, restaurantName, deliveryFee);

    if (added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} +'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau restaurant'),
        content: Text(
          'Votre panier contient déjà des articles de ${cart.restaurantName}. '
          'Voulez-vous le vider pour commander chez $restaurantName ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Vider le panier'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      cart.replaceCartWithItem(item, restaurantId, restaurantName, deliveryFee);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} +'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.available ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.price.toStringAsFixed(0)} CFA'),
                const SizedBox(height: 4),
                if (item.available)
                  InkWell(
                    onTap: () => _handleAdd(context),
                    child: const Icon(Icons.add_circle_outline, size: 26),
                  )
                else
                  const Text('Indisponible', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(review.userName),
      subtitle: Text(review.comment),
      trailing: Text('⭐ ${review.rating}'),
    );
  }
}
