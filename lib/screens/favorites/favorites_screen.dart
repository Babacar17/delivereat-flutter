import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/app_strings.dart';
import '../../widgets/restaurant_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoriteProvider>();
    final lang = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('my_favorites', lang))),
      body: _buildBody(provider, lang),
    );
  }

  Widget _buildBody(FavoriteProvider provider, String lang) {
    switch (provider.state) {
      case FavoriteState.loading:
        return const Center(child: CircularProgressIndicator());

      case FavoriteState.error:
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

      case FavoriteState.empty:
        return Center(child: Text(AppStrings.t('empty_favorites', lang)));

      case FavoriteState.loaded:
        return ListView.builder(
          itemCount: provider.favorites.length,
          itemBuilder: (context, index) =>
              RestaurantCard(restaurant: provider.favorites[index]),
        );
    }
  }
}
