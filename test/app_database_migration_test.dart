import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// #250/#253 — `onUpgrade` used to be a no-op, so a device with pre-schema-11
/// data kept a physically stale `boats` table missing `polar_json` (added at
/// schemaVersion 11), and Drift's generated non-nullable column read crashed.
/// The fix drops and recreates every table on any version bump.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('app_database_migration_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test(
      'opening AppDatabase against a stale on-disk schema (missing a column, '
      'old user_version) upgrades cleanly instead of crashing', () async {
    final path = '${tempDir.path}/stale.sqlite';

    // Simulate a device that installed before #236 added `polar_json`: a
    // `boats` table without that column, and `checklistGroups` non-empty so
    // DatabaseService.init()'s reseed sentinel wouldn't fire on its own.
    final rawDb = sqlite3.sqlite3.open(path);
    rawDb.execute('''
      CREATE TABLE boats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supabase_id TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL DEFAULT ''
      );
    ''');
    rawDb.execute("INSERT INTO boats (supabase_id, name) VALUES ('abc', 'Old Boat');");
    rawDb.execute('''
      CREATE TABLE checklist_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT ''
      );
    ''');
    rawDb.execute("INSERT INTO checklist_groups (name) VALUES ('Pre-departure');");
    rawDb.execute('PRAGMA user_version = 5;'); // below current schemaVersion
    rawDb.close();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    // Any query forces Drift to reconcile schemaVersion vs. user_version,
    // running onUpgrade — must not throw despite the missing column.
    final boats = await db.select(db.boats).get();
    expect(boats, isEmpty,
        reason: 'wipe-and-recreate must drop the stale row, not try to '
            'read it through the new (incompatible) column set');

    // The new column must exist and be usable post-migration.
    await db.into(db.boats).insert(BoatsCompanion.insert(
          name: const Value('New Boat'),
          polarJson: const Value('[]'),
        ));
    final reread = await db.select(db.boats).get();
    expect(reread, hasLength(1));
    expect(reread.single.polarJson, '[]');

    // checklistGroups must also have been wiped — DatabaseService.init()'s
    // reseed sentinel relies on this being empty after a fresh/upgraded DB.
    final groups = await db.select(db.checklistGroups).get();
    expect(groups, isEmpty);
  });

  test('a brand-new database (never opened before) still uses onCreate normally',
      () async {
    final path = '${tempDir.path}/fresh.sqlite';
    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final boats = await db.select(db.boats).get();
    expect(boats, isEmpty);
  });
}
