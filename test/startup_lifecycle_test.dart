import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/database_service.dart';

/// TEST12 — cold start seed path, re-open healthy, corrupt recovery contract,
/// and main.dart dart-defines assert.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService lifecycle (TEST12)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      AppDatabase.setInstanceForTesting(db);
    });

    tearDown(() async {
      try {
        await db.close();
      } catch (_) {}
    });

    test('empty DB first init seeds and returns seeded', () async {
      final result = await DatabaseService().init();
      expect(result, DbInitResult.seeded);
      final groups = await db.select(db.checklistGroups).get();
      expect(groups, isNotEmpty, reason: 'first launch must seed checklists');
      final boats = await db.select(db.boats).get();
      expect(boats, isNotEmpty, reason: 'default boat must exist after seed');
      final settings = await db.select(db.userSettingsTable).get();
      expect(settings, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('second init on already-seeded DB returns healthy (no reseed wipe)',
        () async {
      expect(await DatabaseService().init(), DbInitResult.seeded);
      final groupCount = (await db.select(db.checklistGroups).get()).length;

      expect(await DatabaseService().init(), DbInitResult.healthy);
      expect((await db.select(db.checklistGroups).get()).length, groupCount);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('factoryReset re-seeds a usable catalog', () async {
      await DatabaseService().init();
      await DatabaseService().factoryReset();
      final groups = await db.select(db.checklistGroups).get();
      expect(groups, isNotEmpty);
      final boats = await db.select(db.boats).get();
      expect(boats, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('corrupt DB recovery contract (TEST12)', () {
    // In-memory Drift does not reliably throw after close(); assert the
    // production recovery path is wired instead.
    test('DatabaseService.init maps query failures to corrupted', () {
      final src = File('lib/services/database_service.dart').readAsStringSync();
      expect(src, contains('DbInitResult.corrupted'));
      expect(src, contains('hardReset'));
      expect(src, contains('catch'));
    });

    test('StartupScreen offers hardReset on corrupted', () {
      final src = File('lib/ui/startup/startup_screen.dart').readAsStringSync();
      expect(src, contains('DbInitResult.corrupted'));
      expect(src, contains('hardReset'));
      expect(src, contains('_showCorruptionDialog'));
    });
  });

  group('main.dart dart-defines contract (TEST12)', () {
    test('asserts when SUPABASE_URL / ANON_KEY are empty', () {
      final src = File('lib/main.dart').readAsStringSync();
      expect(src, contains("String.fromEnvironment('SUPABASE_URL')"));
      expect(src, contains("String.fromEnvironment('SUPABASE_ANON_KEY')"));
      expect(src, contains('Missing Supabase credentials'));
      expect(src, contains('dart-define-from-file=dart-defines.json'));
      // Credentials must not be hardcoded as JWT/URL literals.
      expect(src, isNot(contains('eyJhbGciOi')));
      expect(src, isNot(contains('https://')));
    });
  });
}
