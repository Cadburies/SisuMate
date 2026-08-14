import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:sisu_mate/core/app_router.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/location_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/settings/llm_api_key_dialog.dart';
import 'package:sisu_mate/ui/settings/settings_screen.dart';
import 'package:sisu_mate/ui/shopping/shopping_item_ai_dialog.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #334 — nearest-shop online action: no key → AI API Keys; key without
/// grounded search says so; location fail asks for a city instead of inventing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeAuthBackend authBackend;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authBackend = FakeAuthBackend();
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    authBackend.dispose();
    await db.close();
  });

  ShoppingItem rum() => ShoppingItem()
    ..name = 'Duty-free rum'
    ..quantity = 1
    ..origin = 'bar';

  Future<void> seedBoat({String? llmApiKey, String? llmApiKeyProvider}) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKeys: Value(llmApiKey == null || llmApiKeyProvider == null
              ? '[]'
              : jsonEncode([
                  {
                    'provider': llmApiKeyProvider,
                    'apiKey': llmApiKey,
                    'shared': false,
                  },
                ])),
          activeLlmProvider: Value(llmApiKeyProvider),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );
  }

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  testWidgets('#334 no key: Find nearest shop opens Settings + AI API Keys',
      (tester) async {
    await seedBoat();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ShoppingItemAiDialog(item: rum()),
                ),
                child: const Text('open-shop'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => SettingsScreen(
            openAiKeys: state.uri.queryParameters['openAiKeys'] == '1',
          ),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container(),
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-shop'));
    await tester.pumpAndSettle();
    expect(find.byType(ShoppingItemAiDialog), findsOneWidget);
    expect(find.textContaining('Offline shopping guide'), findsOneWidget);

    await tester.ensureVisible(find.text('Find nearest shop (online)'));
    await tester.tap(find.text('Find nearest shop (online)'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ShoppingItemAiDialog), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(LlmApiKeyDialog), findsOneWidget);
    expect(find.text('AI API Keys'), findsWidgets);
    expect(find.text('None set — bring your own to use AI features'),
        findsOneWidget);
    expect(
      find.textContaining(
          'AI features only work when the app is online, this key is valid'),
      findsOneWidget,
    );
    expect(find.textContaining('tokens/credits remaining'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'xAI (Grok) API Key'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'OpenAI API Key'), findsOneWidget);
    expect(
      find.textContaining(
          'Store a key for each provider you use, and pick which one is active'),
      findsOneWidget,
    );
  });

  testWidgets('#334 OpenAI key does not invent shops from a stale completion',
      (tester) async {
    await seedBoat(llmApiKey: 'sk-test', llmApiKeyProvider: 'openai');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container(),
      child: MaterialApp(
        home: Scaffold(body: ShoppingItemAiDialog(item: rum())),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Region / country (optional AI)'),
        'Cape Town');
    await tester.ensureVisible(find.text('Find nearest shop (online)'));
    await tester.tap(find.text('Find nearest shop (online)'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('doesn\'t support live web/X search'),
        findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });

  testWidgets('#334 location denied + empty region asks for a city',
      (tester) async {
    await seedBoat(llmApiKey: 'sk-test', llmApiKeyProvider: 'openai');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container(),
      child: MaterialApp(
        home: Scaffold(
          body: ShoppingItemAiDialog(
            item: rum(),
            locationService: const _DeniedLocation(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Find nearest shop (online)'));
    await tester.tap(find.text('Find nearest shop (online)'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.textContaining('Turn on location, or type a city / region'),
      findsOneWidget,
    );
    expect(find.textContaining('doesn\'t support live web/X search'),
        findsNothing);
  });
}

class _DeniedLocation extends LocationService {
  const _DeniedLocation();

  @override
  Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 12),
  }) async =>
      const LocationResult.failure(LocationFailureReason.permissionDenied);
}
