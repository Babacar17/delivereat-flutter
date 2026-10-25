import 'dart:async';
import 'package:dio/dio.dart';
import 'constants.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio dio;
  bool _isRefreshing = false;
  final List<void Function(bool success)> _pendingRequests = [];

  void Function()? onSessionExpired;

  ApiClient() {
    dio = Dio(BaseOptions(baseUrl: '${ApiConstants.baseUrl}/api'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isTokenExpired =
              error.response?.statusCode == 401 &&
              error.response?.data?['error']?['code'] == 'TOKEN_EXPIRED';

          if (!isTokenExpired) {
            handler.next(error);
            return;
          }

          bool refreshed;
          if (_isRefreshing) {
            // On attend le refresh en cours ET on récupère son résultat réel,
            // au lieu de supposer qu'il a réussi.
            refreshed = await _waitForRefresh();
          } else {
            _isRefreshing = true;
            refreshed = await _refreshTokens();
            _isRefreshing = false;
            _releasePending(refreshed);
          }

          if (!refreshed) {
            // Le refresh a échoué : on ne retente pas avec un token
            // toujours invalide, on laisse l'erreur remonter proprement.
            handler.next(error);
            return;
          }

          try {
            final newToken = await TokenStorage.getAccessToken();
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            final response = await dio.fetch(opts);
            handler.resolve(response);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<bool> _refreshTokens() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) {
        onSessionExpired?.call();
        return false;
      }

      final response = await Dio(
        BaseOptions(baseUrl: '${ApiConstants.baseUrl}/api'),
      ).post('/auth/refresh', data: {'refreshToken': refreshToken});

      await TokenStorage.saveTokens(
        response.data['accessToken'],
        response.data['refreshToken'],
      );
      return true;
    } catch (_) {
      await TokenStorage.clear();
      onSessionExpired?.call();
      return false;
    }
  }

  Future<bool> _waitForRefresh() {
    final completer = Completer<bool>();
    _pendingRequests.add((success) => completer.complete(success));
    return completer.future;
  }

  void _releasePending(bool success) {
    for (final cb in _pendingRequests) {
      cb(success);
    }
    _pendingRequests.clear();
  }
}
