import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/AuthProvider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/app_strings.dart';
import '../../services/restaurant_service.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/category_chip_list.dart';
import '../favorites/favorites_screen.dart';
import '../order/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/offline_banner.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RestaurantProvider>();
      provider.loadCategories();
      provider.loadFirstPage();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<RestaurantProvider>().loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<RestaurantProvider>();
    final lang = context.watch<LocaleProvider>().languageCode;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.t('hello', lang)} ${auth.currentUser?.name ?? ''}',
        ),
        actions: [
          IconButton(
            icon: Text(
              lang == 'fr' ? 'EN' : 'FR',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            tooltip: AppStrings.t('language', lang),
            onPressed: () {
              context.read<LocaleProvider>().setLanguage(
                lang == 'fr' ? 'en' : 'fr',
              );
            },
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: AppStrings.t('dark_mode', lang),
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: AppStrings.t('search_hint', lang),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  context.read<RestaurantProvider>().onSearchChanged(value),
            ),
          ),
          CategoryChipList(categories: provider.categories),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<SortOption>(
                  hint: Text(AppStrings.t('sort_by', lang)),
                  items: [
                    DropdownMenuItem(
                      value: SortOption.rating,
                      child: Text(AppStrings.t('rating', lang)),
                    ),
                    DropdownMenuItem(
                      value: SortOption.deliveryTime,
                      child: Text(AppStrings.t('delivery_time', lang)),
                    ),
                    DropdownMenuItem(
                      value: SortOption.deliveryFee,
                      child: Text(AppStrings.t('delivery_fee', lang)),
                    ),
                  ],
                  onChanged: (value) =>
                      context.read<RestaurantProvider>().setSort(value),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(provider, lang)),
        ],
      ),
    );
  }

  Widget _buildBody(RestaurantProvider provider, String lang) {
    switch (provider.state) {
      case LoadState.initial:
      case LoadState.loading:
        return const Center(child: CircularProgressIndicator());

      case LoadState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage ?? AppStrings.t('error', lang)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.loadFirstPage(),
                child: Text(AppStrings.t('retry', lang)),
              ),
            ],
          ),
        );

      case LoadState.empty:
        return Center(child: Text(AppStrings.t('no_results', lang)));

      case LoadState.loaded:
      case LoadState.loadingMore:
        return ListView.builder(
          controller: _scrollController,
          itemCount:
              provider.restaurants.length +
              (provider.state == LoadState.loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= provider.restaurants.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return RestaurantCard(restaurant: provider.restaurants[index]);
          },
        );
    }
  }
}
