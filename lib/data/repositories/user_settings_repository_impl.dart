import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';

/// User settings (singleton, `id` = 1) on Drift (S1).
class UserSettingsRepositoryImpl implements UserSettingsRepository {
  final AppDatabase db;

  UserSettingsRepositoryImpl(this.db);

  UserSettings _toDomain(UserSettingsRow r) => UserSettings()
    ..id = r.id
    ..activeBoatSupabaseId = r.activeBoatSupabaseId
    ..showHiddenItems = r.showHiddenItems
    ..isPro = r.isPro
    ..proExpiresAt = r.proExpiresAt
    ..selectedBoatId = r.selectedBoatId
    ..userId = r.userId
    ..isDarkMode = r.isDarkMode
    ..unitPrefsJson = r.unitPrefsJson
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified
    ..recentEmails = (jsonDecode(r.recentEmails) as List).cast<String>()
    ..fromName = r.fromName
    ..replyToEmail = r.replyToEmail
    ..boatName = r.boatName
    ..freeEditsUsed = r.freeEditsUsed;

  UserSettingsTableCompanion _companion(UserSettings s) =>
      UserSettingsTableCompanion(
        id: const Value(1),
        activeBoatSupabaseId: Value(s.activeBoatSupabaseId),
        showHiddenItems: Value(s.showHiddenItems),
        isPro: Value(s.isPro),
        proExpiresAt: Value(s.proExpiresAt),
        selectedBoatId: Value(s.selectedBoatId),
        userId: Value(s.userId),
        isDarkMode: Value(s.isDarkMode),
        unitPrefsJson: Value(s.unitPrefsJson),
        isSynced: Value(s.isSynced),
        lastModified: Value(s.lastModified),
        recentEmails: Value(jsonEncode(s.recentEmails)),
        fromName: Value(s.fromName),
        replyToEmail: Value(s.replyToEmail),
        boatName: Value(s.boatName),
        freeEditsUsed: Value(s.freeEditsUsed),
      );

  @override
  Future<UserSettings?> getSettings() async {
    final row = await db.select(db.userSettingsTable).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Stream<UserSettings?> watchSettings() {
    return db
        .select(db.userSettingsTable)
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    settings.lastModified = DateTime.now().toUtc();
    await db
        .into(db.userSettingsTable)
        .insertOnConflictUpdate(_companion(settings));
  }
}
