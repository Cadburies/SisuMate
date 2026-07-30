import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/user_settings_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

// User settings (singleton, id=1) on Drift (S1).
void main() {
  late AppDatabase db;
  late UserSettingsRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = UserSettingsRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  group('UserSettingsRepositoryImpl CRUD', () {
    test('Read: getSettings returns null before any settings exist', () async {
      expect(await repo.getSettings(), isNull);
    });

    test('Create/Update: updateSettings persists the single settings row',
        () async {
      await repo.updateSettings(UserSettings()..fromName = 'S/V Serenity');

      final settings = await repo.getSettings();
      expect(settings, isNotNull);
      expect(settings!.fromName, 'S/V Serenity');
    });

    test(
        'Update: a second updateSettings call overwrites the same row, not a new one',
        () async {
      await repo.updateSettings(UserSettings()..fromName = 'First');
      await repo.updateSettings(UserSettings()..fromName = 'Second');

      final all = await db.select(db.userSettingsTable).get();
      expect(all, hasLength(1));
      expect(all.single.fromName, 'Second');
    });

    test('recentEmails round-trips through the JSON column', () async {
      await repo.updateSettings(
          UserSettings()..recentEmails = ['a@x.com', 'b@y.com']);

      final settings = await repo.getSettings();
      expect(settings!.recentEmails, ['a@x.com', 'b@y.com']);
    });
  });
}
