import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthProvider(this._authService);

  AuthStatus status = AuthStatus.unknown;
  User? currentUser;

  Future<void> checkSession() async {
    if (await TokenStorage.hasSession()) {
      try {
        currentUser = await _authService.getMe();
        status = AuthStatus.authenticated;
      } catch (_) {
        await TokenStorage.clear();
        status = AuthStatus.unauthenticated;
      }
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    currentUser = await _authService.login(email, password);
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    currentUser = await _authService.register(name, email, password);
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void updateUser(User updated) {
    currentUser = updated;
    notifyListeners();
  }

  /// Appelé par le callback onSessionExpired de l'ApiClient
  /// quand le refresh token est définitivement invalide.
  void forceLogout() {
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
