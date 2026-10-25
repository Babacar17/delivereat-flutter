import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../models/restaurant_detail.dart';
import '../models/review.dart';
import '../services/restaurant_detail_service.dart';

enum DetailState { loading, loaded, error }

class RestaurantDetailProvider extends ChangeNotifier {
  final RestaurantDetailService _service;
  RestaurantDetailProvider(this._service);

  RestaurantDetail? detail;
  List<Review> reviews = [];
  DetailState state = DetailState.loading;
  String? errorMessage;
  bool isSubmittingReview = false;
  String? reviewError;

  Future<void> load(String restaurantId) async {
    state = DetailState.loading;
    notifyListeners();
    try {
      detail = await _service.getRestaurantDetail(restaurantId);
      reviews = await _service.getReviews(restaurantId);
      state = DetailState.loaded;
    } on AppError catch (e) {
      errorMessage = e.message;
      state = DetailState.error;
    } catch (_) {
      errorMessage = 'Une erreur est survenue';
      state = DetailState.error;
    }
    notifyListeners();
  }

  Future<bool> submitReview(
    String restaurantId,
    int rating,
    String comment,
  ) async {
    isSubmittingReview = true;
    reviewError = null;
    notifyListeners();

    try {
      await _service.addReview(restaurantId, rating, comment);
      reviews = await _service.getReviews(restaurantId);
      isSubmittingReview = false;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      // Gère notamment 409 ALREADY_REVIEWED sans crasher l'écran
      reviewError = e.message;
      isSubmittingReview = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavorite() async {
    if (detail == null) return;
    final wasFavorite = detail!.info.isFavorite;
    detail = RestaurantDetail(
      info: detail!.info.copyWith(isFavorite: !wasFavorite),
      menu: detail!.menu,
    );
    notifyListeners();

    try {
      await _service.toggleFavorite(detail!.info.id, wasFavorite);
    } catch (_) {
      detail = RestaurantDetail(
        info: detail!.info.copyWith(isFavorite: wasFavorite),
        menu: detail!.menu,
      );
      notifyListeners();
    }
  }
}
