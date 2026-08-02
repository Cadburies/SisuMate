import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/revenuecat_service.dart';
import 'services/admob_service.dart';
import 'services/error_log_service.dart';
import 'services/provider_breadcrumbs.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'core/di.dart';

// Values are compiled in via --dart-define-from-file=dart-defines.json
// Never bundle credentials as Flutter assets.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// App-wide GoRouter (T3). Created once; not a Riverpod provider so tests that
/// pump individual screens without the full router still work.
final appRouter = createAppRouter();

/// #147/#176 follow-up: recent provider activity for exception-level error
/// log entries (see `ErrorLogService.providerBreadcrumbsProvider`).
final _providerBreadcrumbs = ProviderBreadcrumbs();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // #121: capture every framework error / uncaught async error to the local
  // error log from the very first frame onward. Chains the previous handler
  // (there isn't one today, but this must never silently replace one added
  // later) so the normal debug red-screen/console output is unaffected —
  // this only adds capture. Cheap + synchronous; does not touch RT1 timing.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    unawaited(ErrorLogService().logFlutterError(details));
    previousOnError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      ErrorLogService().logException(error, stack, context: 'uncaught async error'),
    );
    return true;
  };
  ErrorLogService.routeHintProvider =
      () => appRouter.routerDelegate.currentConfiguration.uri.toString();
  ErrorLogService.providerBreadcrumbsProvider = () => _providerBreadcrumbs.recent;

  assert(
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty,
    'Missing Supabase credentials. Run with: flutter run --dart-define-from-file=dart-defines.json',
  );

  // Supabase is required for auth session restore; keep it before first frame.
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseAnonKey,
  );

  // The local database is NOT initialised here — StartupScreen handles it so
  // the UI can show a loading state and a recovery dialog if the DB is corrupt.
  //
  // RT1: do NOT await RevenueCat / AdMob before runApp — they blocked first
  // paint (~dozens of skipped frames). They start after the first frame.
  runApp(ProviderScope(
    observers: [_providerBreadcrumbs],
    child: const SisuMateApp(),
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initDeferredSdks());
  });
}

/// Non-critical SDKs — safe after splash has painted (RT1).
Future<void> _initDeferredSdks() async {
  // Parallel; each has its own try/catch and circuit-breaker.
  await Future.wait<void>([
    RevenueCatService().init(),
    AdMobService().init(),
  ]);
  // #123: preload an interstitial right after init so the free-tier Complete
  // gate never races a fresh 500ms load (and the singleton keeps it alive).
  AdMobService().createInterstitialAd();
  // #121: app version + Pro status for error-log context — deferred so
  // RevenueCatService's internal init() doesn't run during first paint.
  ErrorLogService().initDeferredContext();
}

class SisuMateApp extends ConsumerWidget {
  const SisuMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // PRO3: keep RevenueCat appUserId aligned with Supabase auth.
    ref.listen(authStateProvider, (prev, next) {
      final user = next.asData?.value;
      unawaited(RevenueCatService().linkSupabaseUserId(user?.id));
    });

    return MaterialApp.router(
      title: 'Sisu Mate',
      theme: sisuMateLightTheme,
      darkTheme: sisuMateDarkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
