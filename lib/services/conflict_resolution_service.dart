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

// ── BAI5: field-level prefer-mine / prefer-theirs suggestions ────────────────

/// How one non-meta field compares across local vs remote JSON.
enum FieldDiffKind {
  /// Values equal (including both empty).
  same,

  /// Only local has a non-empty value.
  onlyLocal,

  /// Only remote has a non-empty value.
  onlyRemote,

  /// Both non-empty and different (hard concurrent edit).
  conflict,
}

/// Per-field hint for the user (not auto-applied unless they pick Merge).
enum FieldSideSuggestion {
  /// No choice needed.
  either,

  /// Prefer the local value for this field.
  preferMine,

  /// Prefer the remote / cloud value for this field.
  preferTheirs,

  /// Safe auto-merge path (one side empty) - use [tryFieldMerge].
  mergeable,
}

/// One field in a [ConflictDiffReport].
class FieldDiff {
  final String key;
  final String label;
  final String localDisplay;
  final String remoteDisplay;
  final FieldDiffKind kind;
  final FieldSideSuggestion suggestion;

  const FieldDiff({
    required this.key,
    required this.label,
    required this.localDisplay,
    required this.remoteDisplay,
    required this.kind,
    required this.suggestion,
  });
}

/// Whole-record recommendation when resolving a hard conflict card.
enum OverallConflictSuggestion {
  /// [tryFieldMerge] succeeds - offer "Merge fields" as primary.
  mergeFields,

  /// Majority of hard fields (or LWW) point at local.
  keepMine,

  /// Majority of hard fields (or LWW) point at remote.
  keepCloud,

  /// Hard fields split evenly - no strong side; user must choose.
  mixed,
}

/// BAI5 report: field diffs + a single suggested resolution action.
class ConflictDiffReport {
  final List<FieldDiff> fields;
  final OverallConflictSuggestion overall;
  final String overallReason;
  final bool canAutoMerge;

  const ConflictDiffReport({
    required this.fields,
    required this.overall,
    required this.overallReason,
    required this.canAutoMerge,
  });

  /// Fields that actually differ (UI list).
  List<FieldDiff> get differing =>
      fields.where((f) => f.kind != FieldDiffKind.same).toList();

  int get hardConflictCount =>
      fields.where((f) => f.kind == FieldDiffKind.conflict).length;
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

  /// BAI5: compare [local] vs [remote] field-by-field and suggest mine/theirs/merge.
  ///
  /// Pure / UI-facing - does not write. Meta keys are skipped. Hard conflicts
  /// get a per-field side hint plus an [OverallConflictSuggestion] for the card.
  ConflictDiffReport buildConflictDiff(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final fields = <FieldDiff>[];
    final keys = {...local.keys, ...remote.keys}.toList()..sort();

    for (final key in keys) {
      if (_metaKeys.contains(key)) continue;
      final lv = local[key];
      final rv = remote[key];
      final lEmpty = _isEmpty(lv);
      final rEmpty = _isEmpty(rv);
      final equal = _jsonEq(lv, rv);

      late final FieldDiffKind kind;
      late final FieldSideSuggestion suggestion;
      if (equal) {
        kind = FieldDiffKind.same;
        suggestion = FieldSideSuggestion.either;
      } else if (lEmpty && !rEmpty) {
        kind = FieldDiffKind.onlyRemote;
        suggestion = FieldSideSuggestion.mergeable;
      } else if (rEmpty && !lEmpty) {
        kind = FieldDiffKind.onlyLocal;
        suggestion = FieldSideSuggestion.mergeable;
      } else {
        kind = FieldDiffKind.conflict;
        // Soft hint: longer free-text slightly prefers local (user was typing);
        // otherwise prefer the side with a more recent record stamp.
        suggestion = _suggestHardFieldSide(local, remote, lv, rv);
      }

      fields.add(FieldDiff(
        key: key,
        label: humanizeFieldName(key),
        localDisplay: _displayValue(lv),
        remoteDisplay: _displayValue(rv),
        kind: kind,
        suggestion: suggestion,
      ));
    }

    final canMerge = tryFieldMerge(local, remote) != null;
    final overall = _overallSuggestion(fields, local, remote, canMerge);
    return ConflictDiffReport(
      fields: fields,
      overall: overall.$1,
      overallReason: overall.$2,
      canAutoMerge: canMerge,
    );
  }

  /// Friendly label for JSON keys (`lastPurchasePlace` -> `Last purchase place`).
  static String humanizeFieldName(String key) {
    if (key.isEmpty) return key;
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  FieldSideSuggestion _suggestHardFieldSide(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
    dynamic lv,
    dynamic rv,
  ) {
    // Prefer newer record overall when timestamps differ.
    final localLm = DateTime.tryParse('${local['lastModified'] ?? ''}');
    final remoteLm = DateTime.tryParse('${remote['lastModified'] ?? ''}');
    if (localLm != null && remoteLm != null && localLm != remoteLm) {
      return localLm.isAfter(remoteLm)
          ? FieldSideSuggestion.preferMine
          : FieldSideSuggestion.preferTheirs;
    }
    // Tie-break: longer string often means more intentional edit.
    final ls = lv is String ? lv.trim().length : 0;
    final rs = rv is String ? rv.trim().length : 0;
    if (ls != rs) {
      return ls > rs
          ? FieldSideSuggestion.preferMine
          : FieldSideSuggestion.preferTheirs;
    }
    return FieldSideSuggestion.preferMine;
  }

  (OverallConflictSuggestion, String) _overallSuggestion(
    List<FieldDiff> fields,
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
    bool canMerge,
  ) {
    if (canMerge) {
      final fill = fields
          .where((f) => f.kind == FieldDiffKind.onlyRemote)
          .length;
      final keep = fields
          .where((f) => f.kind == FieldDiffKind.onlyLocal)
          .length;
      return (
        OverallConflictSuggestion.mergeFields,
        'No overlapping edits - safe to merge '
        '($fill from cloud, $keep kept local).',
      );
    }

    final hard = fields.where((f) => f.kind == FieldDiffKind.conflict).toList();
    if (hard.isEmpty) {
      return (
        OverallConflictSuggestion.mixed,
        'No field-level differences detected - pick a side to continue.',
      );
    }

    var mine = 0;
    var theirs = 0;
    for (final f in hard) {
      if (f.suggestion == FieldSideSuggestion.preferMine) mine++;
      if (f.suggestion == FieldSideSuggestion.preferTheirs) theirs++;
    }

    if (mine > theirs) {
      return (
        OverallConflictSuggestion.keepMine,
        'Suggested: Keep mine ($mine of ${hard.length} conflicting '
        'field${hard.length == 1 ? '' : 's'} lean this device).',
      );
    }
    if (theirs > mine) {
      return (
        OverallConflictSuggestion.keepCloud,
        'Suggested: Keep cloud ($theirs of ${hard.length} conflicting '
        'field${hard.length == 1 ? '' : 's'} lean the other device).',
      );
    }

    // Split hard fields - fall back to lastModified.
    final localLm = DateTime.tryParse('${local['lastModified'] ?? ''}');
    final remoteLm = DateTime.tryParse('${remote['lastModified'] ?? ''}');
    if (localLm != null && remoteLm != null) {
      if (localLm.isAfter(remoteLm)) {
        return (
          OverallConflictSuggestion.keepMine,
          'Fields split evenly - this device was modified more recently.',
        );
      }
      if (remoteLm.isAfter(localLm)) {
        return (
          OverallConflictSuggestion.keepCloud,
          'Fields split evenly - cloud was modified more recently.',
        );
      }
    }
    return (
      OverallConflictSuggestion.mixed,
      'Fields split evenly - choose Keep mine or Keep cloud.',
    );
  }

  static String _displayValue(dynamic v) {
    if (v == null) return '(empty)';
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return '(empty)';
      return t.length > 80 ? '${t.substring(0, 80)}...' : t;
    }
    if (v is List) {
      if (v.isEmpty) return '(empty list)';
      return v.length <= 3
          ? v.map((e) => '$e').join(', ')
          : '${v.length} items';
    }
    if (v is Map) {
      if (v.isEmpty) return '(empty)';
      return '{${v.length} keys}';
    }
    if (v is bool) return v ? 'Yes' : 'No';
    return '$v';
  }

  /// S6: merge when every differing field is empty on one side.
  ///
  /// Returns null if both sides have non-empty, different values for any
  /// non-meta field (true concurrent edit -> user must pick).
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
