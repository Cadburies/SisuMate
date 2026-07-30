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
  /// When true, UI/export show imperial; DB remains metric (UnitConverter).
  bool useImperial = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  // Email / share settings (SH2/SH4)
  List<String> recentEmails = [];
  String? fromName;
  String? replyToEmail;
  String? boatName;

  /// FREE-EDITS: teaser edits/completions the Free tier has used so far.
  int freeEditsUsed = 0;

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
          useImperial == other.useImperial &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          listEquals(recentEmails, other.recentEmails) &&
          fromName == other.fromName &&
          replyToEmail == other.replyToEmail &&
          boatName == other.boatName &&
          freeEditsUsed == other.freeEditsUsed;

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
        useImperial,
        isSynced,
        lastModified,
        Object.hashAll(recentEmails),
        fromName,
        replyToEmail,
        boatName,
        freeEditsUsed,
      ]);

  @override
  String toString() => 'UserSettings(id: $id, '
      'activeBoatSupabaseId: $activeBoatSupabaseId, '
      'showHiddenItems: $showHiddenItems, isPro: $isPro, '
      'proExpiresAt: $proExpiresAt, selectedBoatId: $selectedBoatId, '
      'userId: $userId, isDarkMode: $isDarkMode, '
      'useImperial: $useImperial, isSynced: $isSynced, '
      'lastModified: $lastModified, recentEmails: $recentEmails, '
      'fromName: $fromName, replyToEmail: $replyToEmail, '
      'boatName: $boatName, freeEditsUsed: $freeEditsUsed)';
}