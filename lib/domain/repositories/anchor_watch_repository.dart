import '../../models/models.dart';

abstract class AnchorWatchRepository {
  /// The currently active anchor watch, if any. Null when no anchor is
  /// currently down (or the last one was weighed).
  Stream<AnchorWatch?> watchActive();

  /// Deactivates any existing active watch, then inserts [watch] as the new
  /// active one. Returns it with its assigned [AnchorWatch.id].
  Future<AnchorWatch> dropAnchor(AnchorWatch watch);

  /// Full-row update by [AnchorWatch.id] — used for both moving the anchor
  /// position ("Edit") and changing scope/radius/danger-zone settings.
  Future<void> updateWatch(AnchorWatch watch);

  /// Stops watching (does not delete history — just marks inactive).
  Future<void> weighAnchor(int id);
}
