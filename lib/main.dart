import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'services/auth_service.dart';
import 'services/restaurant_service.dart';
import 'services/restaurant_detail_service.dart';
import 'services/favorite_service.dart';
import 'services/order_service.dart';
import 'providers/AuthProvider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/restaurant_detail_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/order_history_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'providers/connectivity_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  final apiClient = ApiClient();
  final authService = AuthService(apiClient);
  final authProvider = AuthProvider(authService);
  final restaurantService = RestaurantService(apiClient);
  final restaurantDetailService = RestaurantDetailService(apiClient);

  apiClient.onSessionExpired = () {
    authProvider.forceLogout();
    // Redirige vers le login depuis n'importe quel écran, en vidant
    // toute la pile de navigation.
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<RestaurantProvider>(
          create: (_) => RestaurantProvider(restaurantService),
        ),
        ChangeNotifierProvider<RestaurantDetailProvider>(
          create: (_) => RestaurantDetailProvider(restaurantDetailService),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<FavoriteProvider>(
          create: (_) => FavoriteProvider(FavoriteService(apiClient)),
        ),
        ChangeNotifierProvider<OrderHistoryProvider>(
          create: (_) => OrderHistoryProvider(OrderService(apiClient)),
        ),
      ],
      child: const DeliverEatApp(),
    ),
  );
}

class DeliverEatApp extends StatelessWidget {
  const DeliverEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DeliverEat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
