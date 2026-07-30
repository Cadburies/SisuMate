import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/free_edit_gate.dart';

// FREE-EDITS: Free gets a fixed number of tries before the gate locks; Pro is
// always unlimited. `tryConsume`/`remaining` need a real WidgetRef, so we pump
// a throwaway widget just to capture one rather than constructing Ref by hand.
void main() {
  late AppDatabase db;
  late WidgetRef capturedRef;

  Future<void> pumpHarness(WidgetTester tester, {bool isPro = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          if (isPro) isProProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) {
            capturedRef = ref;
            // Actively watch (not just capture ref) so Riverpod subscribes to
            // the stream now, rather than lazily on FreeEditGate's first
            // out-of-band read.
            ref.watch(isProProvider);
            return const SizedBox.shrink();
          }),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.userSettingsTable).insert(
        UserSettingsTableCompanion.insert(id: const Value(1)));
  });

  tearDown(() async => db.close());

  testWidgets('Free consumes exactly freeEditAllowance tries, then locks',
      (tester) async {
    await pumpHarness(tester);

    for (var i = 0; i < FreeEditGate.freeEditAllowance; i++) {
      final remainingBefore = await FreeEditGate.remaining(capturedRef);
      expect(remainingBefore, FreeEditGate.freeEditAllowance - i);
      expect(await FreeEditGate.tryConsume(capturedRef), isTrue);
    }

    expect(await FreeEditGate.remaining(capturedRef), 0);
    expect(await FreeEditGate.tryConsume(capturedRef), isFalse,
        reason: 'allowance exhausted — must lock');
  });

  testWidgets('consuming persists across reads (counter survives reload)',
      (tester) async {
    await pumpHarness(tester);

    await FreeEditGate.tryConsume(capturedRef);
    await FreeEditGate.tryConsume(capturedRef);

    final row = await db.select(db.userSettingsTable).getSingle();
    expect(row.freeEditsUsed, 2);
  });

  testWidgets(
      'Pro: tryConsume is always true and remaining is null (Free-vs-Pro, TEST1b)',
      (tester) async {
    await pumpHarness(tester, isPro: true);

    // Exhaust well past what would lock a Free user — Pro must never lock.
    for (var i = 0; i < FreeEditGate.freeEditAllowance + 3; i++) {
      expect(await FreeEditGate.remaining(capturedRef), null);
      expect(await FreeEditGate.tryConsume(capturedRef), isTrue);
    }

    // Pro never writes the local counter — it's a Free-only concept.
    final row = await db.select(db.userSettingsTable).getSingle();
    expect(row.freeEditsUsed, 0);
  });
}
