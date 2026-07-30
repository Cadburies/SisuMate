import '../../models/models.dart';

abstract class UserSettingsRepository {
  Future<UserSettings?> getSettings();
  Stream<UserSettings?> watchSettings();
  Future<void> updateSettings(UserSettings settings);
}
