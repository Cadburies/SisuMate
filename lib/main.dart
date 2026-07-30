import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/revenuecat_service.dart';
import 'services/admob_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  runApp(const ProviderScope(child: SisuMateApp()));

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
