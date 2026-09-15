import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/i18n/translations.dart';
import 'core/network/api_providers.dart';
import 'core/realtime/socket_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/catalog_providers.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/cart/application/cart_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  } catch (_) {}
  runZonedGuarded(() => runApp(const ProviderScope(child: VyparHubApp())),
      (e, s) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
    }
  });
}

class VyparHubApp extends ConsumerStatefulWidget {
  const VyparHubApp({super.key});

  @override
  ConsumerState<VyparHubApp> createState() => _VyparHubAppState();
}

class _VyparHubAppState extends ConsumerState<VyparHubApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!AppConfig.useMockData) {
      unawaited(ref.read(apiClientProvider).warmUp());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || AppConfig.useMockData) return;
    unawaited(ref.read(apiClientProvider).warmUp());
    unawaited(ref.read(authProvider.notifier).restore());
    ref.invalidate(catalogSnapshotProvider);
    ref.invalidate(pagedProductsProvider);
    ref.invalidate(productsByCategoryProvider);
    ref.invalidate(cartLinesProvider);
    ref.invalidate(unavailableCartLinesProvider);
    ref.read(customerSocketServiceProvider).connect();
    if (ref.read(authProvider) != null) {
      ref.read(cartProvider.notifier).loadFromServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(sessionExpiredProvider, (_, __) {
      unawaited(ref.read(authProvider.notifier).restore());
    });
    ref.listen<ShopProfile?>(authProvider, (_, next) {
      if (next == null) {
        ref.read(customerSocketServiceProvider).disconnect();
      } else {
        ref.read(customerSocketServiceProvider).connect();
      }
    });
    ref.watch(customerSocketBootstrapProvider);

    final router = ref.watch(routerProvider);
    final lang = ref.watch(langProvider);
    return MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        locale: lang == Lang.hi
            ? const Locale('hi', 'IN')
            : const Locale('en', 'IN'),
        supportedLocales: const [Locale('en', 'IN'), Locale('hi', 'IN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        routerConfig: router);
  }
}
