import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/settings/llm_api_key_dialog.dart';
import 'package:sisu_mate/ui/settings/settings_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #334 — `/settings?openAiKeys=1` (and SettingsScreen.openAiKeys) must
/// land on the exact AI API Keys paste-a-token dialog.
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

  testWidgets('openAiKeys: true opens AI API Keys with exact paste-key copy',
      (tester) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKeys: const Value('[]'),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: SettingsScreen(openAiKeys: true),
      ),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LlmApiKeyDialog), findsOneWidget);
    expect(find.text('AI API Keys'), findsWidgets);
    expect(find.text('None set — bring your own to use AI features'),
        findsOneWidget);
    expect(
      find.textContaining(
          'AI features only work when the app is online, this key is valid'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'xAI (Grok) API Key'), findsOneWidget);
    expect(
      find.textContaining(
          'Store a key for each provider you use, and pick which one is active'),
      findsOneWidget,
    );
  });
}
