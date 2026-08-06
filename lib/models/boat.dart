part of 'models.dart';

/// #211: one stored provider key. Replaces #203/#215's single scalar
/// `llmApiKey`/`llmApiKeyProvider` pair — a boat can now hold one key per
/// provider (OpenAI/xAI/Anthropic/Moonshot) instead of the last one entered
/// overwriting whichever was there before.
class LlmApiKeyEntry {
  String provider; // LlmProvider.id — 'openai' | 'xai' | 'anthropic' | 'kimi'
  String apiKey;
  /// #215's per-boat share opt-in, now per-entry: only an entry with
  /// [shared] true is ever pushed with its real [apiKey] to Supabase.
  bool shared;

  LlmApiKeyEntry({
    required this.provider,
    required this.apiKey,
    this.shared = false,
  });

  factory LlmApiKeyEntry.fromJson(Map<String, dynamic> json) => LlmApiKeyEntry(
        provider: json['provider'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        shared: json['shared'] as bool? ?? false,
      );

  /// Full-fidelity local persistence (Drift's `Boats.llmApiKeys` column) —
  /// always the real [apiKey], regardless of [shared]. Local storage must
  /// have the whole truth; only the wire payload ([toJson]) is gated.
  Map<String, dynamic> toStorageJson() => {
        'provider': provider,
        'apiKey': apiKey,
        'shared': shared,
      };

  /// [apiKey] is nulled out when not [shared] — same rule #215 applied at
  /// the whole-boat level, now per entry. An unshared entry still appears
  /// (provider + shared:false) so a remote reader can tell "not shared"
  /// apart from "never existed", matching #215's original field-level
  /// behavior of always pushing the flag and only gating the secret value.
  Map<String, dynamic> toJson() => {
        'provider': provider,
        'apiKey': shared ? apiKey : null,
        'shared': shared,
      };

  /// #215's inbound guarantee, generalized from one key to a list: only an
  /// *actively shared* incoming entry is adopted, so it can overwrite a
  /// stale locally-adopted copy of the *same* provider's shared key (an
  /// owner rotating their key must reach crew) or a crew member's own
  /// independently-entered key for that provider (matching the old
  /// design's "sharing always wins" precedent — not a new behavior). An
  /// incoming entry with shared:false (or a provider missing from
  /// [incoming] entirely) never touches [local]'s entry for that provider —
  /// once shared then un-shared, the last-known-shared value is preserved
  /// locally, not force-cleared (same test-covered behavior #215 shipped).
  static List<LlmApiKeyEntry> mergeInbound({
    required List<LlmApiKeyEntry> local,
    required List<LlmApiKeyEntry> incoming,
  }) {
    final byProvider = {for (final e in local) e.provider: e};
    for (final inc in incoming) {
      if (inc.shared) byProvider[inc.provider] = inc;
    }
    return byProvider.values.toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LlmApiKeyEntry &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          apiKey == other.apiKey &&
          shared == other.shared;

  @override
  int get hashCode => Object.hash(provider, apiKey, shared);

  @override
  String toString() =>
      'LlmApiKeyEntry(provider: $provider, shared: $shared)'; // never the key
}

/// #236: one manually-entered polar data point — boat speed (kt) at a given
/// true wind angle (deg, 0=head-to-wind, 180=dead downwind) and true wind
/// speed (kt). Foundation for real weather routing (#238); no privacy/
/// sync-gating concerns unlike `LlmApiKeyEntry`, so it's pushed/pulled
/// plainly like any other field.
class PolarPoint {
  final double twaDeg;
  final double twsKt;
  final double boatSpeedKt;

  const PolarPoint({
    required this.twaDeg,
    required this.twsKt,
    required this.boatSpeedKt,
  });

  factory PolarPoint.fromJson(Map<String, dynamic> j) => PolarPoint(
        twaDeg: (j['twaDeg'] as num).toDouble(),
        twsKt: (j['twsKt'] as num).toDouble(),
        boatSpeedKt: (j['boatSpeedKt'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'twaDeg': twaDeg,
        'twsKt': twsKt,
        'boatSpeedKt': boatSpeedKt,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarPoint &&
          twaDeg == other.twaDeg &&
          twsKt == other.twsKt &&
          boatSpeedKt == other.boatSpeedKt;

  @override
  int get hashCode => Object.hash(twaDeg, twsKt, boatSpeedKt);
}

/// Parses a stored polar JSON string (`Boat.polarJson`). Malformed/empty
/// input degrades to an empty table, never throws — an empty table means
/// "no polar data configured" (routing/ETA falls back to flat speed).
List<PolarPoint> parsePolarTable(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    final list = jsonDecode(json) as List;
    return list
        .map((e) => PolarPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}

String encodePolarTable(List<PolarPoint> points) =>
    jsonEncode(points.map((p) => p.toJson()).toList());

class Boat {
  Boat();

  int id = 0;
  bool isBought = false;
  bool isHidden = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();
  double? lastPurchasePrice;
  String name = '';
  String? notes;
  String? origin;
  String? photoUrl;
  String supabaseId = '';
  // ownerId: pushed + read (only owners write boats; used by RLS — SHARE6).
  // shareCode: inbound-only (DB-generated), never pushed.
  String? ownerId;
  String? shareCode;
  // #203/#215/#211: bring-your-own-key LLM support, one entry per provider.
  // **Local-only by default** — see [LlmApiKeyEntry.shared]/[toJson] for the
  // per-entry sync gate, and [LlmApiKeyEntry.mergeInbound] for the inbound
  // adopt-only-if-shared guard (`InboundSyncApplier._upsertBoat`).
  List<LlmApiKeyEntry> llmApiKeys = [];
  // Which stored provider to use for AI requests right now (e.g. "switch to
  // Grok, Claude ran out of tokens"). Deliberately **not** in [toJson]/
  // [fromJson] — this is a per-device preference, not per-boat/crew-shared
  // state (a crew member may have entirely different keys configured than
  // the owner), so it never syncs at all, not even opt-in.
  String? activeLlmProvider;
  // #236: manually-entered / learned boat polar table — see `PolarPoint`.
  // Primary routing target; prefers calm-sea measured polars (#276).
  List<PolarPoint> polar = [];
  // #276: per-sea-state polar curves (keys: calm | moderate | rough).
  Map<String, List<PolarPoint>> polarBySeaState = {};

  LlmApiKeyEntry? get activeLlmApiKeyEntry => llmApiKeys
      .where((e) => e.provider == activeLlmProvider)
      .firstOrNull;

  factory Boat.fromJson(Map<String, dynamic> json) {
    Map<String, List<PolarPoint>> parseMulti(dynamic raw) {
      if (raw is! Map) return {};
      final out = <String, List<PolarPoint>>{};
      for (final e in raw.entries) {
        final list = e.value;
        if (list is! List) continue;
        out[e.key.toString()] = [
          for (final item in list)
            if (item is Map)
              PolarPoint.fromJson(Map<String, dynamic>.from(item)),
        ];
      }
      return out;
    }

    return Boat()
      ..isBought = json['isBought'] ?? false
      ..isHidden = json['isHidden'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified'])
      ..lastPurchasePrice = json['lastPurchasePrice']?.toDouble()
      ..name = json['name'] ?? ''
      ..notes = json['notes']
      ..origin = json['origin']
      ..photoUrl = json['photoUrl']
      ..supabaseId = json['supabaseId'] ?? ''
      ..ownerId = json['ownerId']
      ..shareCode = json['shareCode']
      ..llmApiKeys = (json['llmApiKeys'] as List? ?? const [])
          .map((e) => LlmApiKeyEntry.fromJson(e as Map<String, dynamic>))
          .toList()
      ..polar = (json['polar'] as List? ?? const [])
          .map((e) => PolarPoint.fromJson(e as Map<String, dynamic>))
          .toList()
      ..polarBySeaState = parseMulti(json['polarBySeaState']);
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'name': name,
    'isBought': isBought,
    'isHidden': isHidden,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
    'lastPurchasePrice': lastPurchasePrice,
    'notes': notes,
    'origin': origin,
    'photoUrl': photoUrl,
    // ownerId is pushed (only owners write boats) so RLS can validate ownership
    // on insert/update. shareCode stays inbound-only (DB-generated).
    'ownerId': ownerId,
    'llmApiKeys': llmApiKeys.map((e) => e.toJson()).toList(),
    // activeLlmProvider intentionally absent — see the field's doc comment.
    'polar': polar.map((p) => p.toJson()).toList(),
    'polarBySeaState': {
      for (final e in polarBySeaState.entries)
        e.key: e.value.map((p) => p.toJson()).toList(),
    },
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Boat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isBought == other.isBought &&
          isHidden == other.isHidden &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          lastPurchasePrice == other.lastPurchasePrice &&
          name == other.name &&
          notes == other.notes &&
          origin == other.origin &&
          photoUrl == other.photoUrl &&
          supabaseId == other.supabaseId &&
          ownerId == other.ownerId &&
          shareCode == other.shareCode &&
          listEquals(llmApiKeys, other.llmApiKeys) &&
          activeLlmProvider == other.activeLlmProvider &&
          listEquals(polar, other.polar) &&
          _mapPolarEquals(polarBySeaState, other.polarBySeaState);

  @override
  int get hashCode => Object.hashAll([
        id,
        isBought,
        isHidden,
        isSynced,
        lastModified,
        lastPurchasePrice,
        name,
        notes,
        origin,
        photoUrl,
        supabaseId,
        ownerId,
        shareCode,
        Object.hashAll(llmApiKeys),
        activeLlmProvider,
        Object.hashAll(polar),
        Object.hashAll(
          polarBySeaState.entries.map(
            (e) => Object.hash(e.key, Object.hashAll(e.value)),
          ),
        ),
      ]);

  @override
  String toString() => 'Boat(id: $id, supabaseId: $supabaseId, name: $name, '
      'isBought: $isBought, isHidden: $isHidden, isSynced: $isSynced, '
      'lastModified: $lastModified, lastPurchasePrice: $lastPurchasePrice, '
      'notes: $notes, origin: $origin, photoUrl: $photoUrl, '
      'ownerId: $ownerId, shareCode: $shareCode, '
      'llmApiKeys: $llmApiKeys, ' // entries' own toString never leaks a key
      'activeLlmProvider: $activeLlmProvider)';
}

bool _mapPolarEquals(
  Map<String, List<PolarPoint>> a,
  Map<String, List<PolarPoint>> b,
) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    final other = b[e.key];
    if (other == null || !listEquals(e.value, other)) return false;
  }
  return true;
}
