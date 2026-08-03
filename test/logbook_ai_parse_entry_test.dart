import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/logbook/ai_log_entry_parse_dialog.dart';
import 'package:sisu_mate/ui/logbook/logbook_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #220 / #208: the AI-assisted "parse from freeform text" FAB must be
/// distinct from the normal offline "Add Entry" FAB, never blended into it.
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

  Future<void> pumpScreen(WidgetTester tester) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
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
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LogbookScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('both the AI-parse and normal add FABs render, distinctly',
      (tester) async {
    await pumpScreen(tester);

    // #218 also puts an auto_awesome icon in the title bar, so disambiguate
    // by widget type rather than icon alone.
    expect(find.widgetWithIcon(FloatingActionButton, Icons.auto_awesome),
        findsOneWidget);
    expect(find.widgetWithIcon(FloatingActionButton, Icons.add),
        findsOneWidget);
  });

  testWidgets('tapping the AI FAB opens the freeform parse dialog first, '
      'not the normal entry form', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('AI: Parse freeform entry'));
    await tester.pumpAndSettle();

    expect(find.byType(AiLogEntryParseDialog), findsOneWidget);
    expect(find.text('New Log Entry'), findsNothing);
  });

  testWidgets('the normal add FAB still opens the plain entry form directly',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('New Log Entry'), findsOneWidget);
    expect(find.byType(AiLogEntryParseDialog), findsNothing);
  });
}
