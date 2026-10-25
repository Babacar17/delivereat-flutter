import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/errors.dart';
import '../models/category.dart';
import '../models/restaurant.dart';
import '../models/paginated_response.dart';

enum SortOption { rating, deliveryTime, deliveryFee }

class RestaurantService {
  final ApiClient _client;
  RestaurantService(this._client);

  Future<List<Category>> getCategories() async {
    try {
      final res = await _client.dio.get('/categories');
      final list = res.data['data'] as List; // <-- corrigé
      return list.map((e) => Category.fromJson(e)).toList();
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<PaginatedResponse<Restaurant>> getRestaurants({
    required int page,
    String? search,
    String? categoryId,
    SortOption? sort,
  }) async {
    try {
      final res = await _client.dio.get(
        '/restaurants',
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'category': categoryId,
          if (sort != null) 'sort': _sortParam(sort),
        },
      );
      return PaginatedResponse.fromJson(res.data, Restaurant.fromJson);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  String _sortParam(SortOption sort) {
    switch (sort) {
      case SortOption.rating:
        return 'rating';
      case SortOption.deliveryTime:
        return 'deliveryTime';
      case SortOption.deliveryFee:
        return 'deliveryFee';
    }
  }
}
