import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/passage_readiness_provider.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';
import 'package:sisu_mate/ui/home/home_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #278 — home passage readiness + suggestions are swipe-dismissable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<ProviderContainer> pumpHome(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(false)),
      boatSuggestionsProvider.overrideWith(
        (ref) => const [
          BoatSuggestion(
            id: 's1',
            title: 'Check oil',
            detail: 'Overdue service',
            severity: SuggestionSeverity.watch,
          ),
        ],
      ),
      passageReadinessProvider.overrideWith(
        (ref) => const PassageReadiness(
          status: ReadinessStatus.needsAttention,
          blockers: ['Safety checklist incomplete'],
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    return container;
  }

  testWidgets('swipe dismisses passage readiness strip for the session',
      (tester) async {
    final container = await pumpHome(tester);

    expect(find.byKey(const ValueKey('home_passage_readiness')), findsOneWidget);
    expect(find.textContaining('thing first'), findsOneWidget);
    expect(find.text('Suggestions'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('home_passage_readiness')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home_passage_readiness')), findsNothing);
    expect(container.read(homePassageReadinessDismissedProvider), isTrue);
    // Suggestions still visible.
    expect(find.text('Suggestions'), findsOneWidget);
  });

  testWidgets('swipe dismisses suggestions strip for the session',
      (tester) async {
    final container = await pumpHome(tester);

    await tester.drag(
      find.byKey(const ValueKey('home_suggestions')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home_suggestions')), findsNothing);
    expect(find.text('Suggestions'), findsNothing);
    expect(container.read(homeSuggestionsDismissedProvider), isTrue);
    // Readiness still visible.
    expect(find.byKey(const ValueKey('home_passage_readiness')), findsOneWidget);
  });
}
