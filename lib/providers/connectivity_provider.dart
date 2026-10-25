import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheck;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    await _checkRealConnectivity();

    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkRealConnectivity();
    });

    _periodicCheck = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkRealConnectivity();
    });
  }

  Future<void> _checkRealConnectivity() async {
    bool hasRealInternet;
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      hasRealInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      hasRealInternet = false;
    }

    final offline = !hasRealInternet;
    debugPrint('Real internet check: hasInternet=$hasRealInternet');
    if (offline != isOffline) {
      isOffline = offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _periodicCheck?.cancel();
    super.dispose();
  }
}
