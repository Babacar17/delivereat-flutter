import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/errors.dart';
import '../models/restaurant.dart';

class FavoriteService {
  final ApiClient _client;
  FavoriteService(this._client);

  Future<List<Restaurant>> getFavorites() async {
    try {
      final res = await _client.dio.get('/me/favorites');
      final list = res.data['data'] as List? ?? res.data as List;
      return list.map((e) => Restaurant.fromJson(e)).toList();
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }
}
