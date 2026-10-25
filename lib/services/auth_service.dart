import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/errors.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _client;
  AuthService(this._client);

  Future<User> register(String name, String email, String password) async {
    try {
      final res = await _client.dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      await TokenStorage.saveTokens(
        res.data['accessToken'],
        res.data['refreshToken'],
      );
      return User.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await TokenStorage.saveTokens(
        res.data['accessToken'],
        res.data['refreshToken'],
      );
      return User.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<User> getMe() async {
    try {
      final res = await _client.dio.get('/auth/me');
      return User.fromJson(res.data);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    try {
      await _client.dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (_) {
      // on vide quand même le storage même si l'appel échoue
    } finally {
      await TokenStorage.clear();
    }
  }
}
