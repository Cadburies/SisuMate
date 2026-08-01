import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/error_log_repository_impl.dart';
import 'package:sisu_mate/services/error_log_service.dart';

/// #121 — ErrorLogService capture, dedupe, and secret redaction.
void main() {
  late AppDatabase db;
  late ErrorLogRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ErrorLogRepositoryImpl(db);
    ErrorLogService.setInstanceForTesting(repo);
  });

  tearDown(() async {
    ErrorLogService.resetInstanceForTests();
    await db.close();
  });

  test('logException writes a row an agent can act on', () async {
    try {
      throw StateError('boom: pantry sync failed');
    } catch (e, st) {
      await ErrorLogService().logException(e, st, context: 'pantry: sync');
    }

    final rows = await repo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.level, 'exception');
    expect(rows.single.message, contains('pantry: sync'));
    expect(rows.single.message, contains('boom: pantry sync failed'));
    expect(rows.single.occurrences, 1);
    expect(rows.single.processedAt, isNull);
  });

  test('logWarning and logError land with their own level', () async {
    await ErrorLogService().logWarning('missing optional file');
    await ErrorLogService().logError('degraded: retrying');

    final rows = await repo.getUnprocessed();
    expect(rows.map((r) => r.level), containsAll(['warning', 'error']));
  });

  test('same fingerprint within a run increments occurrences, not rows',
      () async {
    // Same underlying bug, different exact overflow amount each time (like a
    // real RenderFlex overflow re-firing on every rebuild) — must still
    // dedupe to one row via digit-normalized fingerprinting.
    await ErrorLogService()
        .logError('A RenderFlex overflowed by 12.0 pixels on the right.');
    await ErrorLogService()
        .logError('A RenderFlex overflowed by 45.0 pixels on the right.');
    await ErrorLogService()
        .logError('A RenderFlex overflowed by 3.0 pixels on the right.');

    final rows = await repo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.occurrences, 3);
  });

  test('different messages produce different fingerprints (no over-merge)',
      () async {
    await ErrorLogService().logError('A RenderFlex overflowed on the right.');
    await ErrorLogService().logError('A RenderFlex overflowed on the bottom.');

    final rows = await repo.getUnprocessed();
    expect(rows, hasLength(2));
  });

  test('sourceFile is extracted from an app-code stack frame', () async {
    await ErrorLogService().logError(
      'boom',
      stack: StackTrace.fromString(
        '#0  _Foo.build (package:sisu_mate/ui/home/home_screen.dart:42:10)\n'
        '#1  StatelessElement.build (package:flutter/src/widgets/framework.dart:5000:1)\n',
      ),
    );

    final rows = await repo.getUnprocessed();
    expect(rows.single.sourceFile,
        contains('package:sisu_mate/ui/home/home_screen.dart'));
  });

  test('Authorization/Bearer/apikey values are redacted before storage',
      () async {
    await ErrorLogService().logError(
      'request failed: {"Authorization": "Bearer abc.def.ghi", '
      '"apikey": "eyJsecretvalue"}',
      stack: StackTrace.fromString(
        'Authorization: Bearer super-secret-token-value\n'
        '#0 x (package:sisu_mate/services/sync_service.dart:10:1)',
      ),
    );

    final rows = await repo.getUnprocessed();
    final row = rows.single;
    expect(row.message, isNot(contains('abc.def.ghi')));
    expect(row.message, isNot(contains('eyJsecretvalue')));
    expect(row.stackTrace, isNot(contains('super-secret-token-value')));
    expect(row.message, contains('[redacted]'));
  });

  test('logFlutterError captures a FlutterErrorDetails-shaped report',
      () async {
    await ErrorLogService().logFlutterError(FlutterErrorDetails(
      exception: FlutterError('A RenderFlex overflowed by 8.0 pixels.'),
      stack: StackTrace.current,
      library: 'rendering library',
      context: ErrorDescription('during layout'),
    ));

    final rows = await repo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.level, 'exception');
    expect(rows.single.message, contains('overflowed'));
  });

  test('a failing repository write does not throw out of the public API',
      () async {
    await db.close(); // force the repo's next write to fail
    await expectLater(
      ErrorLogService().logError('after close'),
      completes,
    );
  });
}
