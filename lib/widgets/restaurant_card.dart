import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../screens/restaurant/restaurant_detail_screen.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: restaurant.isOpen ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          leading: Hero(
            tag: 'restaurant-image-${restaurant.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                restaurant.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant),
              ),
            ),
          ),
          title: Text(restaurant.name),
          subtitle: Text(
            '⭐ ${restaurant.rating.toStringAsFixed(1)} · '
            '${restaurant.deliveryTimeLabel} · '
            '${restaurant.deliveryFee.toStringAsFixed(0)} CFA',
          ),
          trailing: !restaurant.isOpen
              ? const Chip(label: Text('Fermé'))
              : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    RestaurantDetailScreen(restaurantId: restaurant.id),
              ),
            );
          },
        ),
      ),
    );
  }
}
