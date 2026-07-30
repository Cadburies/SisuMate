/// Pure conflict-detection decisions for offline-first sync (T5 + S6).
///
/// A **conflict** is when the local row still has unpushed edits (dirty) and the
/// remote version is also newer or different — both devices changed the same
/// record while offline.
///
/// **S6 field merge:** when both sides changed different fields (or only filled
/// empty fields on one side), we auto-merge instead of forcing Keep mine/cloud.
enum InboundAction {
  /// No local row, or local is clean and remote is newer → write remote.
  applyRemote,

  /// Local is already up to date, or local is newer / dirty with older remote.
  skip,

  /// Local dirty AND remote also changed → hold for user resolution
  /// (or try [tryFieldMerge] first).
  conflict,

  /// S6: merged local+remote non-conflicting fields — apply [mergedJson].
  applyMerged,
}

/// Result of a successful S6 field-level merge.
class FieldMergeResult {
  final Map<String, dynamic> merged;
  final List<String> filledFromRemote;
  final List<String> keptLocal;
  const FieldMergeResult({
    required this.merged,
    required this.filledFromRemote,
    required this.keptLocal,
  });
}

class ConflictResolutionService {
  const ConflictResolutionService();

  static const _metaKeys = {
    'lastModified',
    'isSynced',
    'id',
    'supabaseId',
    'boatSupabaseId',
  };

  /// Decide what to do with an incoming remote record.
  ///
  /// [localExists] — a Drift row with this supabaseId exists.
  /// [localDirty] — local `isSynced == false` and/or pending outbox item.
  /// [localLastModified] / [remoteLastModified] — for last-write-wins when clean.
  InboundAction evaluate({
    required bool localExists,
    required bool localDirty,
    required DateTime? localLastModified,
    required DateTime? remoteLastModified,
  }) {
    if (!localExists) return InboundAction.applyRemote;

    final localLm = localLastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
    final remoteLm =
        remoteLastModified ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (localDirty) {
      // Unpushed local work: never auto-overwrite. If remote is strictly
      // newer, surface a conflict so the user can choose (or S6 field-merge).
      if (remoteLm.isAfter(localLm)) {
        return InboundAction.conflict;
      }
      return InboundAction.skip;
    }

    // Clean local: last-write-wins.
    if (remoteLm.isAfter(localLm)) {
      return InboundAction.applyRemote;
    }
    return InboundAction.skip;
  }

  /// S6: merge when every differing field is empty on one side.
  ///
  /// Returns null if both sides have non-empty, different values for any
  /// non-meta field (true concurrent edit → user must pick).
  FieldMergeResult? tryFieldMerge(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final keys = {...local.keys, ...remote.keys};
    final merged = Map<String, dynamic>.from(local);
    final fromRemote = <String>[];
    final keptLocal = <String>[];

    for (final key in keys) {
      if (_metaKeys.contains(key)) continue;
      final lv = local[key];
      final rv = remote[key];
      if (_jsonEq(lv, rv)) continue;
      final lEmpty = _isEmpty(lv);
      final rEmpty = _isEmpty(rv);
      if (lEmpty && !rEmpty) {
        merged[key] = rv;
        fromRemote.add(key);
      } else if (rEmpty && !lEmpty) {
        merged[key] = lv;
        keptLocal.add(key);
      } else {
        // Both non-empty and different → hard conflict.
        return null;
      }
    }

    // Prefer the newer lastModified stamp.
    final localLm = DateTime.tryParse('${local['lastModified'] ?? ''}');
    final remoteLm = DateTime.tryParse('${remote['lastModified'] ?? ''}');
    DateTime stamp = DateTime.now().toUtc();
    if (localLm != null && remoteLm != null) {
      stamp = localLm.isAfter(remoteLm) ? localLm : remoteLm;
    } else if (remoteLm != null) {
      stamp = remoteLm;
    } else if (localLm != null) {
      stamp = localLm;
    }
    merged['lastModified'] = stamp.toIso8601String();
    merged['isSynced'] = false;
    return FieldMergeResult(
      merged: merged,
      filledFromRemote: fromRemote,
      keptLocal: keptLocal,
    );
  }

  static bool _isEmpty(dynamic v) {
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    if (v is List) return v.isEmpty;
    if (v is Map) return v.isEmpty;
    return false;
  }

  static bool _jsonEq(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_jsonEq(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!b.containsKey(k) || !_jsonEq(a[k], b[k])) return false;
      }
      return true;
    }
    return false;
  }
}
