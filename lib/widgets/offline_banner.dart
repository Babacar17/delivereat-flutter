import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/locale_provider.dart';
import '../core/app_strings.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<ConnectivityProvider>().isOffline;
    final lang = context.watch<LocaleProvider>().languageCode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOffline ? 32 : 0,
      color: Colors.redAccent,
      width: double.infinity,
      child: isOffline
          ? Center(
              child: Text(
                AppStrings.t('offline_banner', lang),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
    );
  }
}
