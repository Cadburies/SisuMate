import 'dart:convert';

import '../models/models.dart';
import 'shopping_item_local_guide.dart';

/// One line on a [PortRunStop].
class PortRunLine {
  final String name;
  final String qtyLabel;
  final String origin;
  final String? localName;

  const PortRunLine({
    required this.name,
    required this.qtyLabel,
    required this.origin,
    this.localName,
  });
}

/// One physical (or store-type) stop on a port run.
class PortRunStop {
  final String shopLabel;
  final String kind;
  final String? walk;
  final String? hours;
  final String? till;
  final List<PortRunLine> lines;

  const PortRunStop({
    required this.shopLabel,
    required this.kind,
    this.walk,
    this.hours,
    this.till,
    required this.lines,
  });
}

/// Whole-list shop run. Offline groups by store type; live search fills
/// named shops, walks, hours, and local till names.
class PortRunSheet {
  final String area;
  final List<PortRunStop> stops;
  final List<String> allergenNotes;
  final List<String> skipNotes;
  final String tillSummary;
  final List<String> tips;
  final bool fromLiveSearch;

  const PortRunSheet({
    required this.area,
    required this.stops,
    required this.allergenNotes,
    required this.skipNotes,
    required this.tillSummary,
    required this.tips,
    this.fromLiveSearch = false,
  });
}

/// #337 — offline-first port-run planner. No network.
class ShoppingPortRun {
  ShoppingPortRun._();

  static const kindSupermarket = 'supermarket';
  static const kindLiquor = 'liquor';
  static const kindChandlery = 'chandlery';
  static const kindPharmacy = 'pharmacy';
  static const kindSkip = 'skip';

  static const _kindOrder = [
    kindSupermarket,
    kindLiquor,
    kindChandlery,
    kindPharmacy,
  ];

  static const _offlineShopLabel = {
    kindSupermarket: 'Supermarket / market',
    kindLiquor: 'Liquor / duty-free',
    kindChandlery: 'Chandlery / hardware',
    kindPharmacy: 'Pharmacy',
  };

  /// Marina-office / fuel items are not a walk-to-till stop.
  static bool isMarinaDesk(String name) {
    final n = name.toLowerCase();
    return n.contains('propane') ||
        n.contains('lpg') ||
        n.contains('diesel') ||
        n.contains('petrol') ||
        n.contains('gasoline') ||
        n.contains('fuel dock') ||
        (n.contains('fuel') && !n.contains('lighter'));
  }

  static String kindForOrigin(String origin) {
    switch (origin.toLowerCase().trim()) {
      case 'bar':
      case 'drinks':
      case 'beverage':
        return kindLiquor;
      case 'spares':
      case 'parts':
      case 'hardware':
      case 'safety':
        return kindChandlery;
      case 'medical':
      case 'pharmacy':
        return kindPharmacy;
      default:
        return kindSupermarket;
    }
  }

  static String qtyLabel(ShoppingItem item) {
    final qty = item.quantity < 1 ? 1 : item.quantity;
    final unit = (item.unit != null && item.unit!.trim().isNotEmpty)
        ? ' ${item.unit!.trim()}'
        : '';
    return '×$qty$unit';
  }

  static String weekdayName(DateTime at) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[at.weekday - 1];
  }

  /// Draft run from the pending cart. Works with no key / no network.
  static PortRunSheet planOffline({
    required List<ShoppingItem> items,
    List<GuestProfile> guests = const [],
    List<PantryIngredient> pantry = const [],
    List<BarIngredient> bar = const [],
    String? coarseLocation,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final pending = items
        .where((i) => !i.isHidden && !i.isBought)
        .toList(growable: false);

    final skip = <ShoppingItem>[];
    final byKind = <String, List<ShoppingItem>>{};
    for (final item in pending) {
      if (isMarinaDesk(item.name)) {
        skip.add(item);
        continue;
      }
      final kind = kindForOrigin(item.origin);
      byKind.putIfAbsent(kind, () => []).add(item);
    }

    final stops = <PortRunStop>[];
    for (final kind in _kindOrder) {
      final group = byKind[kind];
      if (group == null || group.isEmpty) continue;
      stops.add(PortRunStop(
        shopLabel: _offlineShopLabel[kind] ?? kind,
        kind: kind,
        lines: [
          for (final i in group)
            PortRunLine(
              name: i.name,
              qtyLabel: qtyLabel(i),
              origin: i.origin,
            ),
        ],
      ));
    }

    var priced = 0;
    var total = 0.0;
    for (final i in pending) {
      final line = i.lineEstimate;
      if (line == null) continue;
      priced++;
      total += line;
    }
    final till = priced == 0
        ? 'No pack prices on file yet'
        : '${total.toStringAsFixed(2)} on file · $priced of ${pending.length} priced';

    final area = (coarseLocation != null && coarseLocation.trim().isNotEmpty)
        ? coarseLocation.trim()
        : 'Port not set — type a marina / city, or allow location';

    final tips = <String>[
      '${weekdayName(at)} — closest supermarket is often crushed on charter changeover (Sat/Sun).',
      'Offline draft groups by store type. Name the shops (live) fills real names, walk times, and hours.',
    ];
    for (final kind in byKind.keys) {
      final hints = ShoppingItemLocalGuide.storeHintsForOrigin(
        byKind[kind]!.first.origin,
      );
      if (hints.isNotEmpty) tips.add(hints.first);
    }

    return PortRunSheet(
      area: area,
      stops: stops,
      allergenNotes: allergenNotes(
        items: pending,
        guests: guests,
        pantry: pantry,
        bar: bar,
      ),
      skipNotes: [
        for (final i in skip) '${i.name} — marina office / fuel dock, not a shop',
      ],
      tillSummary: till,
      tips: tips,
    );
  }

  static List<String> allergenNotes({
    required List<ShoppingItem> items,
    required List<GuestProfile> guests,
    required List<PantryIngredient> pantry,
    required List<BarIngredient> bar,
  }) {
    if (guests.isEmpty) return const [];
    final pantryBy = {
      for (final p in pantry) p.name.toLowerCase().trim(): p,
    };
    final barBy = {
      for (final b in bar) b.name.toLowerCase().trim(): b,
    };
    final out = <String>[];
    final seen = <String>{};
    for (final g in guests) {
      final first = _firstName(g.name);
      final restricted = {
        ...g.allergenRestrictions.map((s) => s.toLowerCase().trim()),
        ...g.dietaryRequirements.map((s) => s.toLowerCase().trim()),
      }..removeWhere((s) => s.isEmpty);
      if (restricted.isEmpty) continue;
      for (final item in items) {
        final key = item.name.toLowerCase().trim();
        final tags = <String>{
          ...?pantryBy[key]?.allergenTags,
          ...?barBy[key]?.allergenTags,
          ...?pantryBy[key]?.dietaryTags,
        }.map((s) => s.toLowerCase().trim()).toSet();
        final hits = restricted.intersection(tags);
        if (hits.isEmpty) continue;
        final note = '$first: ${item.name} tagged ${hits.join(', ')}';
        if (seen.add(note)) out.add(note);
      }
    }
    return out;
  }

  static String _firstName(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'Guest';
    return t.split(RegExp(r'\s+')).first;
  }

  /// Best-effort parse of a grounded-search JSON body into a [PortRunSheet].
  /// Returns null if the model did not produce usable JSON (caller shows
  /// cleaned prose instead of citation soup).
  static PortRunSheet? tryParseLive(
    String raw, {
    required List<ShoppingItem> items,
  }) {
    final map = _extractJsonMap(raw);
    if (map == null) return null;
    final stopsRaw = map['stops'];
    if (stopsRaw is! List || stopsRaw.isEmpty) return null;

    final byName = {
      for (final i in items) i.name.toLowerCase().trim(): i,
    };

    final stops = <PortRunStop>[];
    for (final s in stopsRaw) {
      if (s is! Map) continue;
      final shop = (s['shop'] ?? s['shopLabel'] ?? '').toString().trim();
      if (shop.isEmpty) continue;
      final kind = (s['kind'] ?? kindSupermarket).toString().trim();
      final lines = <PortRunLine>[];
      final itemsRaw = s['items'];
      if (itemsRaw is List) {
        for (final it in itemsRaw) {
          String name;
          String? say;
          if (it is String) {
            name = it;
          } else if (it is Map) {
            name = (it['name'] ?? '').toString();
            final sayRaw = (it['say'] ?? it['localName'])?.toString().trim();
            say = (sayRaw == null || sayRaw.isEmpty) ? null : sayRaw;
          } else {
            continue;
          }
          name = name.trim();
          if (name.isEmpty) continue;
          final match = byName[name.toLowerCase()];
          lines.add(PortRunLine(
            name: match?.name ?? name,
            qtyLabel: match == null ? '' : qtyLabel(match),
            origin: match?.origin ?? '',
            localName: say,
          ));
        }
      }
      if (lines.isEmpty) continue;
      stops.add(PortRunStop(
        shopLabel: shop,
        kind: kind,
        walk: _optStr(s['walk']),
        hours: _optStr(s['hours']),
        till: _optStr(s['till']),
        lines: lines,
      ));
    }
    if (stops.isEmpty) return null;

    return PortRunSheet(
      area: _optStr(map['area']) ?? 'This port',
      stops: stops,
      allergenNotes: _strList(map['allergens']),
      skipNotes: _strList(map['skip']),
      tillSummary: _optStr(map['tillTotal']) ?? '',
      tips: _strList(map['tips']),
      fromLiveSearch: true,
    );
  }

  /// Strip markdown/citation junk so a failed JSON parse is still readable.
  static String cleanProse(String raw) {
    var s = raw;
    s = s.replaceAll(RegExp(r'```(?:json)?'), '');
    s = s.replaceAll('```', '');
    s = s.replaceAll(RegExp(r'\*\*'), '');
    s = s.replaceAll(RegExp(r'\[\[\d+\]\]\([^)]*\)'), '');
    s = s.replaceAll(RegExp(r'\[(\d+)\]\([^)]*\)'), '');
    s = s.replaceAll(RegExp(r'\[\[(\d+)\]\]'), '');
    return s.trim();
  }

  static Map<String, dynamic>? _extractJsonMap(String raw) {
    var s = raw.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final m = fence.firstMatch(s);
    if (m != null) s = m.group(1)!.trim();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(s.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _optStr(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static List<String> _strList(Object? v) {
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
  }
}
