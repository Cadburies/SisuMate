part of 'models.dart';

class UserSettings {
  int id = 1;
  String? activeBoatSupabaseId;
  bool showHiddenItems = false;
  bool isPro = false;
  DateTime? proExpiresAt;
  String? selectedBoatId;
  String? userId;
  bool isDarkMode = true; // dark is the default (theme.md §1)
  /// JSON [AppUnitPrefs] — per-category display units (DB stays metric).
  String unitPrefsJson = '';
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  // Email / share settings (SH2/SH4)
  List<String> recentEmails = [];
  String? fromName;
  String? replyToEmail;
  String? boatName;

  /// FREE-EDITS: teaser edits/completions the Free tier has used so far.
  int freeEditsUsed = 0;

  /// #256 — default chain-scope ratio new anchor drops are pre-filled with.
  double defaultAnchorScopeRatio = 5.0;

  /// #263 — set via the Anchor Alarm's gateway setup/onboarding screen
  /// (auto-discovered or manually entered), stored so the user doesn't
  /// re-enter it every session. Empty means "use the dart-defines default,
  /// if any" — these override that when non-empty. Local-only (this whole
  /// table never syncs) since a Hub login is boat-specific, not something
  /// to carry to another device.
  String predictwindHubLocalUrl = '';
  String predictwindHubUsername = '';
  String predictwindHubPassword = '';

  /// #263 — Yacht Devices YDWG-02 (or equivalent) web/NMEA gateway on the
  /// boat LAN. Separate from the PredictWind DataHub path. Empty → use
  /// dart-define / built-in defaults (`YDWGIP`, `YDWG_USERNAME`,
  /// `YDWG_PASSWORD`). Local-only, never synced.
  String ydwgUrl = '';
  String ydwgUsername = '';
  String ydwgPassword = '';

  /// #263 — Home Assistant as another instrument path (local and/or remote
  /// Nabu Casa / reverse-proxy URL). Token is a long-lived access token.
  /// Entity IDs optional — GPS entity should expose lat/lon attributes
  /// (e.g. `device_tracker.boat`) or use separate lat/lon sensors.
  String homeAssistantUrl = '';
  String homeAssistantRemoteUrl = '';
  String homeAssistantToken = '';
  String homeAssistantGpsEntity = '';
  String homeAssistantLatEntity = '';
  String homeAssistantLonEntity = '';
  String homeAssistantWindSpeedEntity = '';
  String homeAssistantWindDirEntity = '';
  String homeAssistantDepthEntity = '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          activeBoatSupabaseId == other.activeBoatSupabaseId &&
          showHiddenItems == other.showHiddenItems &&
          isPro == other.isPro &&
          proExpiresAt == other.proExpiresAt &&
          selectedBoatId == other.selectedBoatId &&
          userId == other.userId &&
          isDarkMode == other.isDarkMode &&
          unitPrefsJson == other.unitPrefsJson &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          listEquals(recentEmails, other.recentEmails) &&
          fromName == other.fromName &&
          replyToEmail == other.replyToEmail &&
          boatName == other.boatName &&
          freeEditsUsed == other.freeEditsUsed &&
          defaultAnchorScopeRatio == other.defaultAnchorScopeRatio &&
          predictwindHubLocalUrl == other.predictwindHubLocalUrl &&
          predictwindHubUsername == other.predictwindHubUsername &&
          predictwindHubPassword == other.predictwindHubPassword &&
          ydwgUrl == other.ydwgUrl &&
          ydwgUsername == other.ydwgUsername &&
          ydwgPassword == other.ydwgPassword &&
          homeAssistantUrl == other.homeAssistantUrl &&
          homeAssistantRemoteUrl == other.homeAssistantRemoteUrl &&
          homeAssistantToken == other.homeAssistantToken &&
          homeAssistantGpsEntity == other.homeAssistantGpsEntity &&
          homeAssistantLatEntity == other.homeAssistantLatEntity &&
          homeAssistantLonEntity == other.homeAssistantLonEntity &&
          homeAssistantWindSpeedEntity == other.homeAssistantWindSpeedEntity &&
          homeAssistantWindDirEntity == other.homeAssistantWindDirEntity &&
          homeAssistantDepthEntity == other.homeAssistantDepthEntity;

  @override
  int get hashCode => Object.hashAll([
        id,
        activeBoatSupabaseId,
        showHiddenItems,
        isPro,
        proExpiresAt,
        selectedBoatId,
        userId,
        isDarkMode,
        unitPrefsJson,
        isSynced,
        lastModified,
        Object.hashAll(recentEmails),
        fromName,
        replyToEmail,
        boatName,
        freeEditsUsed,
        defaultAnchorScopeRatio,
        predictwindHubLocalUrl,
        predictwindHubUsername,
        predictwindHubPassword,
        ydwgUrl,
        ydwgUsername,
        ydwgPassword,
        homeAssistantUrl,
        homeAssistantRemoteUrl,
        homeAssistantToken,
        homeAssistantGpsEntity,
        homeAssistantLatEntity,
        homeAssistantLonEntity,
        homeAssistantWindSpeedEntity,
        homeAssistantWindDirEntity,
        homeAssistantDepthEntity,
      ]);

  @override
  String toString() => 'UserSettings(id: $id, '
      'activeBoatSupabaseId: $activeBoatSupabaseId, '
      'showHiddenItems: $showHiddenItems, isPro: $isPro, '
      'proExpiresAt: $proExpiresAt, selectedBoatId: $selectedBoatId, '
      'userId: $userId, isDarkMode: $isDarkMode, '
      'unitPrefsJson: $unitPrefsJson, isSynced: $isSynced, '
      'lastModified: $lastModified, recentEmails: $recentEmails, '
      'fromName: $fromName, replyToEmail: $replyToEmail, '
      'boatName: $boatName, freeEditsUsed: $freeEditsUsed, '
      'defaultAnchorScopeRatio: $defaultAnchorScopeRatio, '
      'predictwindHubLocalUrl: $predictwindHubLocalUrl, '
      'predictwindHubUsername: $predictwindHubUsername, '
      'ydwgUrl: $ydwgUrl, ydwgUsername: $ydwgUsername, '
      'homeAssistantUrl: $homeAssistantUrl)';
}