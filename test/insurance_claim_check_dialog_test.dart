import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/documents/documents_screen.dart';
import 'package:sisu_mate/ui/documents/insurance_claim_check_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #227: insurance claim likelihood — reached via an Insurance-category
/// document's AI badge (#208 separation from tap-to-view), reasons only
/// over pasted text (no OCR/document pipeline exists), and never claims to
/// be a claims/legal determination. Also exercises the shared
/// `PastedExcerptCheckDialog` extracted at this issue.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required String documentType,
  }) async {
    await db
        .into(db.boats)
        .insert(
          BoatsCompanion.insert(
            supabaseId: const Value('boat_1'),
            name: const Value('Sisu'),
            llmApiKeys: const Value('[]'),
          ),
        );
    await db
        .into(db.userSettingsTable)
        .insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );
    await db
        .into(db.documents)
        .insert(
          DocumentsCompanion.insert(
            supabaseId: const Value('doc_1'),
            boatSupabaseId: const Value('boat_1'),
            title: const Value('Hull Insurance Policy'),
            type: Value(documentType),
          ),
        );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isProProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DocumentsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('an Insurance document shows the AI badge; tapping it opens '
      'the claim-check dialog', (tester) async {
    await pumpScreen(tester, documentType: 'Insurance');

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.byType(InsuranceClaimCheckDialog), findsOneWidget);
    expect(find.text('What happened?'), findsOneWidget);
    expect(find.text('Policy excerpt'), findsOneWidget);
  });

  testWidgets('a non-Insurance document (e.g. Registration) shows no AI '
      'badge', (tester) async {
    await pumpScreen(tester, documentType: 'Registration');

    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });

  testWidgets('with no key configured, asking says so instead of silently '
      'failing', (tester) async {
    await pumpScreen(tester, documentType: 'Insurance');
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'What happened?'),
      'Boom broke loose in a storm and cracked the rail',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Policy excerpt'),
      'Storm damage to fittings is covered up to \$5,000.',
    );
    await tester.tap(find.text('Check offline'));
    await tester.pump();

    expect(find.textContaining('Offline reading'), findsOneWidget);
    expect(find.textContaining('possibly in scope'), findsOneWidget);
    expect(
      find.textContaining('Limit named in the excerpt: \$5,000'),
      findsOneWidget,
    );
    expect(find.textContaining('No AI API key is configured'), findsNothing);

    await tester.tap(find.text('Improve with AI (online)'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });
}
