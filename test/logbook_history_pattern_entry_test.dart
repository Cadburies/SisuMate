import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/logbook/history_pattern_dialog.dart';
import 'package:sisu_mate/ui/logbook/logbook_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #218 / #208: the AI entry point on Captain's Log must be its own
/// distinct icon, not blended into the log list's own actions.
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

  testWidgets('the AI badge renders on the title bar', (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('tapping the AI badge opens the history pattern dialog',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryPatternDialog), findsOneWidget);
    expect(find.text('AI: Recurring Issues'), findsOneWidget);
  });
}
