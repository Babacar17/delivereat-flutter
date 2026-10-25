import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../models/restaurant.dart';
import '../services/favorite_service.dart';

enum FavoriteState { loading, loaded, empty, error }

class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _service;
  FavoriteProvider(this._service);

  List<Restaurant> favorites = [];
  FavoriteState state = FavoriteState.loading;
  String? errorMessage;

  Future<void> load() async {
    state = FavoriteState.loading;
    notifyListeners();
    try {
      favorites = await _service.getFavorites();
      state = favorites.isEmpty ? FavoriteState.empty : FavoriteState.loaded;
    } on AppError catch (e) {
      errorMessage = e.message;
      state = FavoriteState.error;
    } catch (_) {
      errorMessage = 'Une erreur est survenue';
      state = FavoriteState.error;
    }
    notifyListeners();
  }
}
