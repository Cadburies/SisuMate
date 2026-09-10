import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/error_log_repository_impl.dart';
import 'package:sisu_mate/services/error_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    ErrorLogService.providerBreadcrumbsProvider = null;
    await db.close();
  });

  group('#147/#176 follow-up: provider breadcrumbs', () {
    test('exception-level entries carry the current breadcrumb snapshot',
        () async {
      ErrorLogService.providerBreadcrumbsProvider = () => [
            '12:00:00.100 update ProviderElement boatSuggestionsProvider',
            '12:00:00.120 update StreamProviderElement maintenanceTasksProvider',
          ];

      try {
        throw StateError('setState() called during build');
      } catch (e, st) {
        await ErrorLogService().logException(e, st);
      }

      final rows = await repo.getUnprocessed();
      expect(rows.single.debugBreadcrumbs, isNotNull);
      expect(rows.single.debugBreadcrumbs,
          contains('boatSuggestionsProvider'));
      expect(rows.single.debugBreadcrumbs,
          contains('maintenanceTasksProvider'));
    });

    test('warning/error levels do not carry breadcrumbs (kept lean)',
        () async {
      ErrorLogService.providerBreadcrumbsProvider =
          () => ['12:00:00.100 update ProviderElement foo'];

      await ErrorLogService().logWarning('offline retry');
      await ErrorLogService().logError('degraded: retrying');

      final rows = await repo.getUnprocessed();
      expect(rows.every((r) => r.debugBreadcrumbs == null), isTrue);
    });

    test('no breadcrumbs provider registered → null, no crash', () async {
      try {
        throw StateError('boom');
      } catch (e, st) {
        await ErrorLogService().logException(e, st);
      }

      final rows = await repo.getUnprocessed();
      expect(rows.single.debugBreadcrumbs, isNull);
    });

    test(
        'breadcrumbs never affect fingerprint/message — the same underlying '
        'exception still dedupes even as breadcrumbs differ every call '
        '(would otherwise file a new GitHub issue every occurrence)',
        () async {
      var call = 0;
      ErrorLogService.providerBreadcrumbsProvider = () {
        call++;
        return ['12:00:00.$call update ProviderElement someProvider'];
      };

      for (var i = 0; i < 3; i++) {
        try {
          throw StateError('setState() called during build');
        } catch (e, st) {
          await ErrorLogService().logException(e, st);
        }
      }

      final rows = await repo.getUnprocessed();
      expect(rows, hasLength(1),
          reason: 'must still dedupe to one row despite differing '
              'breadcrumbs each call');
      expect(rows.single.occurrences, 3);
    });
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

  test(
      'same underlying widget crash dedupes across occurrences despite a '
      'different Flutter hashCode suffix each time', () async {
    // Element/State toString() appends a short, non-deterministic hex
    // suffix per instance (e.g. "CocktailBatchScreenState#2aca9") — mixed
    // alphanumeric, so digit-only normalization alone doesn't catch it.
    // Found live: this exact gap produced a straight duplicate issue.
    await ErrorLogService().logException(
      Exception(
          'building CocktailBatchScreenState#2aca9: There should be exactly one item'),
      null,
    );
    await ErrorLogService().logException(
      Exception(
          'building CocktailBatchScreenState#f19a2: There should be exactly one item'),
      null,
    );

    final rows = await repo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.occurrences, 2);
  });

  test('fingerprint hex never has a leading sign (breaks GitHub search)',
      () async {
    // FNV-1a is a plain (signed-on-native) int; the fix forces .toUnsigned(64)
    // before hex-encoding. Fuzz a spread of *distinct* fingerprints (letters,
    // not digits — digits alone would normalize away and all collapse into
    // one deduped row) since a specific string that reproduces a negative
    // raw hash isn't hand-crafted here.
    for (var i = 0; i < 200; i++) {
      final code = String.fromCharCodes(
          [97 + i % 26, 97 + (i ~/ 26) % 26, 97 + (i ~/ 676) % 26]);
      await ErrorLogService().logError('probe message $code here');
    }
    final rows = await repo.getUnprocessed();
    expect(rows, hasLength(200));
    for (final row in rows) {
      expect(row.fingerprint, isNot(startsWith('-')));
      expect(row.fingerprint, matches(RegExp(r'^[0-9a-f]{16}$')));
    }
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

  test(
      'logFlutterError extracts a --track-widget-creation file:// location '
      '(#159/#160/#161: previously always null for overflow errors)',
      () async {
    // A hand-built FlutterErrorDetails whose informationCollector mimics
    // what debugTransformDebugCreator injects for a real RenderFlex overflow
    // — a DiagnosticsNode block containing the offending widget's
    // file:///.../lib/....dart:LINE:COL creation location (not a package:
    // URI — see the doc comment on _appFrameFileUri). Exercises this without
    // depending on the real transform pipeline (covered separately by the
    // real-overflow widget test below).
    await ErrorLogService().logFlutterError(FlutterErrorDetails(
      exception: FlutterError('A RenderFlex overflowed by 5.6 pixels on the bottom.'),
      library: 'rendering library',
      context: ErrorDescription('during layout'),
      informationCollector: () => [
        DiagnosticsBlock(
          name: 'The relevant error-causing widget was',
          children: [
            ErrorDescription(
              'Column Column:file:///Users/dev/SisuMate/lib/ui/components/'
              'item_detail_shell.dart:187:14',
            ),
          ],
        ),
      ],
    ));

    final rows = await repo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.sourceFile,
        'package:sisu_mate/ui/components/item_detail_shell.dart:187:14');
  });

  testWidgets(
      'logFlutterError on a real RenderFlex overflow captures this test '
      "file's own creation location end-to-end (via details.toString(), "
      'not a hand-reconstructed message)', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterErrorDetails? captured;
    FlutterError.onError = (details) {
      captured ??= details;
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 10,
          child: Column(
            children: List.generate(
                5, (_) => Container(height: 50, color: Colors.red)),
          ),
        ),
      ),
    ));

    expect(captured, isNotNull,
        reason: 'the deliberately oversized Column must have overflowed');
    await ErrorLogService().logFlutterError(captured!);

    final rows = await repo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.message, contains('overflowed'));
    expect(rows.single.sourceFile, isNotNull,
        reason: 'must resolve a creation location for a widget built in '
            'this test file, matching what a real overflow in lib/ code '
            'would resolve to a package:sisu_mate/....dart:LINE:COL frame');
    expect(rows.single.sourceFile, contains('error_log_service_test.dart'));
    expect(rows.single.sourceFile, matches(RegExp(r':\d+:\d+$')));
  });

  test('a failing repository write does not throw out of the public API',
      () async {
    await db.close(); // force the repo's next write to fail
    await expectLater(
      ErrorLogService().logError('after close'),
      completes,
    );
  });

  group('#247/#249/#251/#254: logUncaughtError classification', () {
    test('a RealtimeSubscribeException logs as warning, not exception',
        () async {
      const error = RealtimeSubscribeException(
          RealtimeSubscribeStatus.timedOut, 'channel timed out');

      await ErrorLogService().logUncaughtError(
        error,
        StackTrace.current,
        context: 'uncaught async error',
      );

      final rows = await repo.getUnprocessed();
      expect(rows, hasLength(1));
      expect(rows.single.level, 'warning');
      expect(rows.single.message, contains('realtime subscribe failed'));
      expect(rows.single.message, contains('uncaught async error'));
    });

    test('a non-Realtime uncaught error still logs as exception (no regression)',
        () async {
      try {
        throw StateError('some other uncaught bug');
      } catch (e, st) {
        await ErrorLogService().logUncaughtError(
          e,
          st,
          context: 'uncaught async error',
        );
      }

      final rows = await repo.getUnprocessed();
      expect(rows, hasLength(1));
      expect(rows.single.level, 'exception');
      expect(rows.single.message, contains('some other uncaught bug'));
    });
  });

  group('#341 test-mode flag + upload', () {
    test('enabled=false writes no rows', () async {
      ErrorLogService.enabled = false;
      await ErrorLogService().logWarning('should not persist');
      try {
        throw StateError('should not persist');
      } catch (e, st) {
        await ErrorLogService().logException(e, st);
      }
      expect(await repo.getUnprocessed(), isEmpty);
    });

    test('enabled=true still writes as today', () async {
      ErrorLogService.enabled = true;
      await ErrorLogService().logWarning('tester period');
      expect(await repo.getUnprocessed(), hasLength(1));
    });

    test('uploadUnsent pushes unprocessed rows and marks them processed',
        () async {
      await ErrorLogService().logWarning('device boom');
      expect(await repo.getUnprocessed(), hasLength(1));

      var sent = 0;
      final n = await ErrorLogService().uploadUnsent(
        uploader: (rows) async {
          sent = rows.length;
          expect(rows.single.message, contains('device boom'));
          return 'uploaded:test';
        },
      );
      expect(n, 1);
      expect(sent, 1);
      expect(await repo.getUnprocessed(), isEmpty);

      final n2 = await ErrorLogService().uploadUnsent(
        uploader: (rows) async {
          fail('must not re-send processed rows');
        },
      );
      expect(n2, 0);
    });
  });
}
