import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/errors.dart';
import '../models/restaurant_detail.dart';
import '../models/review.dart';

class RestaurantDetailService {
  final ApiClient _client;
  RestaurantDetailService(this._client);

  Future<RestaurantDetail> getRestaurantDetail(String id) async {
    try {
      final res = await _client.dio.get('/restaurants/$id');
      return RestaurantDetail.fromJson(res.data);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<List<Review>> getReviews(String restaurantId) async {
    try {
      final res = await _client.dio.get('/restaurants/$restaurantId/reviews');
      final list = res.data['data'] as List? ?? res.data as List;
      return list.map((e) => Review.fromJson(e)).toList();
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  /// Retourne null en cas de succès, ou l'AppError si ça échoue
  /// (notamment 409 ALREADY_REVIEWED, géré normalement par l'appelant).
  Future<void> addReview(
    String restaurantId,
    int rating,
    String comment,
  ) async {
    try {
      await _client.dio.post(
        '/restaurants/$restaurantId/reviews',
        data: {'rating': rating, 'comment': comment},
      );
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<void> toggleFavorite(
    String restaurantId,
    bool currentlyFavorite,
  ) async {
    try {
      if (currentlyFavorite) {
        await _client.dio.delete('/me/favorites/$restaurantId');
      } else {
        await _client.dio.post('/me/favorites/$restaurantId');
      }
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }
}
