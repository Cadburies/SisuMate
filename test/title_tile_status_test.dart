import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/components/title_tile.dart';

import 'test_helpers/platform_mocks.dart';

/// #348: tester/debug grant shows Tester 2026 instead of Pro/Free.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    debugTestModeOverrideForTests = null;
  });

  tearDown(() async {
    debugTestModeOverrideForTests = null;
    await db.close();
  });

  Future<void> pumpTile(WidgetTester tester, {required bool isPro}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          isProProvider.overrideWith((ref) => Stream.value(isPro)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TitleTile(title: 'Checklists')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('tester mode status line is Tester 2026, not Pro or Free',
      (tester) async {
    debugTestModeOverrideForTests = true;
    await pumpTile(tester, isPro: true);
    expect(find.textContaining('Tester 2026'), findsOneWidget);
    expect(find.textContaining('Pro'), findsNothing);
    expect(find.textContaining('Free'), findsNothing);
    await unmount(tester);
  });

  testWidgets('non-tester Pro still reads Pro', (tester) async {
    debugTestModeOverrideForTests = false;
    await pumpTile(tester, isPro: true);
    expect(find.textContaining('Pro'), findsOneWidget);
    expect(find.textContaining('Tester 2026'), findsNothing);
    await unmount(tester);
  });

  testWidgets('non-tester Free still reads Free', (tester) async {
    debugTestModeOverrideForTests = false;
    await pumpTile(tester, isPro: false);
    expect(find.textContaining('Free'), findsOneWidget);
    expect(find.textContaining('Tester 2026'), findsNothing);
    await unmount(tester);
  });
}
