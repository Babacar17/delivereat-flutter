import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../models/category.dart' as model;
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';

enum LoadState { initial, loading, loaded, empty, error, loadingMore }

class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _service;
  RestaurantProvider(this._service);

  List<model.Category> categories = [];
  List<Restaurant> restaurants = [];
  LoadState state = LoadState.initial;
  String? errorMessage;

  int _page = 1;
  bool _hasNextPage = true;
  String _search = '';
  String? _categoryId;
  SortOption? _sort;
  Timer? _debounce;

  Future<void> loadCategories() async {
    try {
      categories = await _service.getCategories();
      debugPrint('Catégories chargées: ${categories.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
    }
  }

  Future<void> loadFirstPage() async {
    _page = 1;
    _hasNextPage = true;

    // Si on a déjà des restaurants en cache et qu'on est hors ligne,
    // on les garde affichés plutôt que de vider l'écran.
    if (restaurants.isNotEmpty) {
      state = LoadState.loadingMore; // évite un écran de chargement vide
    } else {
      state = LoadState.loading;
    }
    notifyListeners();

    try {
      final response = await _service.getRestaurants(
        page: _page,
        search: _search,
        categoryId: _categoryId,
        sort: _sort,
      );
      restaurants = response.items;
      _hasNextPage = response.hasNextPage;
      state = restaurants.isEmpty ? LoadState.empty : LoadState.loaded;
    } on AppError catch (e) {
      if (restaurants.isNotEmpty) {
        // Mode hors ligne : on garde le cache affiché, pas d'écran d'erreur
        state = LoadState.loaded;
      } else {
        errorMessage = e.message;
        state = LoadState.error;
      }
    } catch (_) {
      if (restaurants.isNotEmpty) {
        state = LoadState.loaded;
      } else {
        errorMessage = 'Une erreur est survenue';
        state = LoadState.error;
      }
    }
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    if (!_hasNextPage || state == LoadState.loadingMore) return;
    state = LoadState.loadingMore;
    notifyListeners();

    try {
      final response = await _service.getRestaurants(
        page: _page + 1,
        search: _search,
        categoryId: _categoryId,
        sort: _sort,
      );
      restaurants.addAll(response.items);
      _page += 1;
      _hasNextPage = response.hasNextPage;
      state = LoadState.loaded;
    } catch (_) {
      // On revient à "loaded" pour permettre un nouveau essai au prochain scroll
      state = LoadState.loaded;
    }
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = query;
      loadFirstPage();
    });
  }

  void setCategory(String? categoryId) {
    _categoryId = categoryId;
    loadFirstPage();
  }

  void setSort(SortOption? sort) {
    _sort = sort;
    loadFirstPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
