import '../core/units.dart';
import '../models/models.dart';

/// #327 — catalog purchase package (how the item is sold at the shop).
///
/// Distinct from recipe **need** (g/ml) and boat **stock** (on-hand base).
/// Built from structured purchase columns — never from on-hand quantity.
class PurchaseSpec {
  /// Measure inside one SKU in a metric base unit (`ml`, `g`, or `each`).
  final double? sizeBase;
  final String? sizeUnit;

  /// Shop noun (bottle, bag, pack, case, …).
  final String noun;

  /// Inner units in the SKU (1 for a bottle, 12 for a case).
  final int unitsPerPurchase;

  /// Size of one inner unit when [unitsPerPurchase] > 1 (200 for 12×200 ml).
  final double? innerSizeBase;

  /// Shelf price for **one** purchase unit (not per ml/g).
  final double? pricePerUnit;

  const PurchaseSpec({
    this.sizeBase,
    this.sizeUnit,
    this.noun = 'pack',
    this.unitsPerPurchase = 1,
    this.innerSizeBase,
    this.pricePerUnit,
  });

  bool get hasSize =>
      sizeBase != null && sizeBase! > 0 && sizeUnit != null && sizeUnit!.isNotEmpty;

  /// Derived display label (`250ml bottle`, `12×200ml case`). Persist into
  /// [PantryIngredient.lastKnownPriceUnit] / bar equivalent — do not parse
  /// that string back as the source of truth.
  String get unitLabel {
    if (unitsPerPurchase > 1 &&
        innerSizeBase != null &&
        sizeUnit != null &&
        sizeUnit!.isNotEmpty) {
      return '$unitsPerPurchase×${_fmtSize(innerSizeBase!, sizeUnit!)} $noun';
    }
    if (sizeBase != null && sizeUnit != null && sizeUnit!.isNotEmpty) {
      return '${_fmtSize(sizeBase!, sizeUnit!)} $noun';
    }
    return noun.isEmpty ? 'pack' : noun;
  }

  static String _fmtSize(double v, String unit) {
    if (unit == 'ml' && v >= 1000 && v % 1000 == 0) {
      return '${(v / 1000).round()}L';
    }
    if (unit == 'g' && v >= 1000 && v % 1000 == 0) {
      return '${(v / 1000).round()}kg';
    }
    final n = v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
    return '$n$unit';
  }

  factory PurchaseSpec.fromFields({
    double? purchaseSizeBase,
    String? purchaseBaseUnit,
    String? purchaseNoun,
    int unitsPerPurchase = 1,
    double? innerSizeBase,
    double? price,
  }) {
    final noun = (purchaseNoun != null && purchaseNoun.trim().isNotEmpty)
        ? purchaseNoun.trim()
        : 'pack';
    return PurchaseSpec(
      sizeBase: purchaseSizeBase,
      sizeUnit: purchaseBaseUnit,
      noun: noun,
      unitsPerPurchase: unitsPerPurchase < 1 ? 1 : unitsPerPurchase,
      innerSizeBase: innerSizeBase,
      pricePerUnit: price,
    );
  }

  factory PurchaseSpec.fromPantry(PantryIngredient p) => PurchaseSpec.fromFields(
        purchaseSizeBase: p.purchaseSizeBase,
        purchaseBaseUnit: p.purchaseBaseUnit,
        purchaseNoun: p.purchaseNoun,
        unitsPerPurchase: p.unitsPerPurchase,
        innerSizeBase: p.innerSizeBase,
        price: p.lastKnownPrice,
      );

  factory PurchaseSpec.fromBar(BarIngredient b) => PurchaseSpec.fromFields(
        purchaseSizeBase: b.purchaseSizeBase,
        purchaseBaseUnit: b.purchaseBaseUnit,
        purchaseNoun: b.purchaseNoun,
        unitsPerPurchase: b.unitsPerPurchase,
        innerSizeBase: b.innerSizeBase,
        price: b.lastKnownPrice,
      );

  /// Seed / import only: lift a human price-unit string + optional qty into
  /// structured fields. Not used for live shortfall math.
  factory PurchaseSpec.fromSeedLabel({
    double? packageQty,
    String? packageUnit,
    String? priceUnit,
    double? price,
    String defaultNoun = 'pack',
  }) {
    final parsed = _parsePurchaseLabel(priceUnit);
    if (parsed != null) {
      return PurchaseSpec(
        sizeBase: parsed.sizeBase,
        sizeUnit: parsed.sizeUnit,
        noun: parsed.noun ?? defaultNoun,
        unitsPerPurchase: parsed.unitsPerPurchase,
        innerSizeBase: parsed.innerSizeBase,
        pricePerUnit: price,
      );
    }
    final countable = _countableUnit(packageUnit);
    if (countable != null) {
      return PurchaseSpec(
        sizeBase: packageQty != null && packageQty > 0 ? packageQty : 1,
        sizeUnit: 'each',
        noun: countable,
        unitsPerPurchase: 1,
        pricePerUnit: price,
      );
    }
    final metric = UnitConverter.toMetric(packageQty, packageUnit);
    if (metric != null && packageQty != null && packageQty > 0) {
      final size = metric.unit == 'kg'
          ? metric.quantity * 1000
          : metric.unit == 'L' || metric.unit == 'l'
              ? metric.quantity * 1000
              : metric.quantity;
      final unit = (metric.unit == 'kg')
          ? 'g'
          : (metric.unit == 'L' || metric.unit == 'l')
              ? 'ml'
              : (metric.unit == 'ml' || metric.unit == 'g')
                  ? metric.unit
                  : null;
      if (unit != null) {
        return PurchaseSpec(
          sizeBase: size,
          sizeUnit: unit,
          noun: defaultNoun,
          pricePerUnit: price,
        );
      }
    }
    return PurchaseSpec(noun: defaultNoun, pricePerUnit: price);
  }

  void applyToPantry(PantryIngredient p) {
    p
      ..purchaseSizeBase = sizeBase
      ..purchaseBaseUnit = sizeUnit
      ..purchaseNoun = noun
      ..unitsPerPurchase = unitsPerPurchase
      ..innerSizeBase = innerSizeBase
      ..lastKnownPriceUnit = unitLabel;
    if (pricePerUnit != null) p.lastKnownPrice = pricePerUnit;
  }

  void applyToBar(BarIngredient b) {
    b
      ..purchaseSizeBase = sizeBase
      ..purchaseBaseUnit = sizeUnit
      ..purchaseNoun = noun
      ..unitsPerPurchase = unitsPerPurchase
      ..innerSizeBase = innerSizeBase
      ..lastKnownPriceUnit = unitLabel
      ..onHandUnit = sizeUnit;
    if (pricePerUnit != null) b.lastKnownPrice = pricePerUnit;
  }
}

class _ParsedLabel {
  final double? sizeBase;
  final String? sizeUnit;
  final String? noun;
  final int unitsPerPurchase;
  final double? innerSizeBase;
  const _ParsedLabel({
    this.sizeBase,
    this.sizeUnit,
    this.noun,
    this.unitsPerPurchase = 1,
    this.innerSizeBase,
  });
}

final _nouns = {
  'bottle',
  'bag',
  'pack',
  'case',
  'jar',
  'block',
  'can',
  'carton',
  'loaf',
  'bunch',
  'each',
  'bulb',
};

/// Parse labels like `250ml bottle`, `1L bottle`, `12x200ml case`, `4-pack`.
_ParsedLabel? _parsePurchaseLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim().toLowerCase();
  final compact = s.replaceAll(' ', '');

  final caseMatch =
      RegExp(r'^(\d+)x(\d+(?:\.\d+)?)(ml|l|g|kg)([a-z]+)?$').firstMatch(compact);
  if (caseMatch != null) {
    final n = int.parse(caseMatch.group(1)!);
    final each = double.parse(caseMatch.group(2)!);
    final u = caseMatch.group(3)!;
    final noun = _nounWord(caseMatch.group(4)) ?? 'case';
    final norm = _normalizeSize(each, u);
    if (norm == null) return null;
    return _ParsedLabel(
      sizeBase: norm.$1 * n,
      sizeUnit: norm.$2,
      noun: noun,
      unitsPerPurchase: n,
      innerSizeBase: norm.$1,
    );
  }

  final nPack = RegExp(r'^(\d+)-?pack$').firstMatch(compact);
  if (nPack != null) {
    return _ParsedLabel(
      noun: 'pack',
      unitsPerPurchase: int.parse(nPack.group(1)!),
    );
  }

  final sizeNoun =
      RegExp(r'^(\d+(?:\.\d+)?)(ml|l|g|kg)([a-z]+)?$').firstMatch(compact);
  if (sizeNoun != null) {
    final norm = _normalizeSize(double.parse(sizeNoun.group(1)!), sizeNoun.group(2)!);
    if (norm == null) return null;
    return _ParsedLabel(
      sizeBase: norm.$1,
      sizeUnit: norm.$2,
      noun: _nounWord(sizeNoun.group(3)),
    );
  }

  if (_nouns.contains(compact)) {
    return _ParsedLabel(noun: compact);
  }
  return null;
}

String? _nounWord(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return _nouns.contains(raw) ? raw : null;
}

String? _countableUnit(String? unit) {
  if (unit == null) return null;
  switch (unit.trim().toLowerCase()) {
    case 'piece':
    case 'pieces':
    case 'count':
    case 'each':
      return 'each';
    case 'bulb':
      return 'bulb';
    case 'bunch':
      return 'bunch';
    case 'loaf':
      return 'loaf';
    case 'whole':
      return 'each';
    case 'stalk':
    case 'stalks':
      return 'each';
    case 'clove':
    case 'cloves':
      return 'each';
    default:
      return null;
  }
}

(double, String)? _normalizeSize(double qty, String unit) {
  switch (unit) {
    case 'ml':
      return (qty, 'ml');
    case 'l':
      return (qty * 1000, 'ml');
    case 'g':
      return (qty, 'g');
    case 'kg':
      return (qty * 1000, 'g');
    default:
      return null;
  }
}

/// One shopping line in **purchase counts**, never raw measure as multiplier.
class ShopPackLine {
  final String name;
  final int packages;
  final String unitLabel;
  final double? pricePerPackage;
  final double? needBase;
  final String? needUnit;
  final double? haveBase;
  final String? note;

  const ShopPackLine({
    required this.name,
    required this.packages,
    required this.unitLabel,
    this.pricePerPackage,
    this.needBase,
    this.needUnit,
    this.haveBase,
    this.note,
  });

  double? get lineEstimate {
    final p = pricePerPackage;
    if (p == null || packages < 1) return null;
    return p * packages;
  }

  String get formatted {
    final pack = packages <= 1 ? '1 × $unitLabel' : '$packages × $unitLabel';
    final needPart = needBase != null && needUnit != null
        ? ' (need ${_fmt(needBase!)} $needUnit'
            '${haveBase != null ? ', have ${_fmt(haveBase!)} $needUnit' : ''})'
        : '';
    return '$name — $pack$needPart';
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}

/// #327 — pure conversion between need / stock / purchase packs.
class QuantityModel {
  const QuantityModel();

  /// Packages to buy: `ceil(max(0, need − have) / packageSize)`.
  int packagesToBuy({
    required double needBase,
    required double haveBase,
    required double packageSizeBase,
  }) {
    if (packageSizeBase <= 0) return needBase > haveBase ? 1 : 0;
    final deficit = needBase - haveBase;
    if (deficit <= 0) return 0;
    return (deficit / packageSizeBase).ceil();
  }

  /// Convert [qty]+[unit] to a metric base shared with [targetUnit] if possible.
  double? toCompatibleBase(double? qty, String? unit, String? targetUnit) {
    if (qty == null) return null;
    final countable = _countableUnit(unit);
    if (countable != null) {
      if (targetUnit == null ||
          targetUnit == 'each' ||
          _countableUnit(targetUnit) != null) {
        return qty;
      }
      return null;
    }
    final m = UnitConverter.toMetric(qty, unit);
    if (m == null) return null;
    var mq = m.quantity;
    var mu = m.unit;
    if (mu == 'kg') {
      mq *= 1000;
      mu = 'g';
    }
    if (mu == 'L' || mu == 'l') {
      mq *= 1000;
      mu = 'ml';
    }
    final t = targetUnit;
    if (t == null || t.isEmpty) return mq;
    if (mu == t) return mq;
    if (mu == 'kg' && t == 'g') return mq * 1000;
    if (mu == 'g' && t == 'kg') return mq / 1000;
    if (mu == 'l' && t == 'ml') return mq * 1000;
    if (mu == 'ml' && t == 'l') return mq / 1000;
    if (mu == 'ml' && t == 'ml') return mq;
    if (mu == 'g' && t == 'g') return mq;
    return null;
  }

  /// On-hand stock for pantry. Not tracked → 0. Tracked + amount → that
  /// amount. Tracked + null → unknown (null), never treated as covered.
  double? pantryOnHandBase(PantryIngredient p, {String? needUnit}) {
    if (!p.inMyPantry) return 0;
    if (p.quantity == null) return null;
    return toCompatibleBase(p.quantity, p.unit ?? p.purchaseBaseUnit, needUnit);
  }

  double? barOnHandBase(BarIngredient b, {String? needUnit}) {
    if (!b.inMyBar) return 0;
    if (b.onHandBase == null) return null;
    return toCompatibleBase(b.onHandBase, b.onHandUnit ?? b.purchaseBaseUnit, needUnit);
  }

  /// Cocktail / bar: pour total → bottles.
  int bottlesFromPours({
    required double pourMlEach,
    required int drinkCount,
    required double bottleMl,
    double onHandMl = 0,
  }) {
    final need = pourMlEach * drinkCount;
    return packagesToBuy(
      needBase: need,
      haveBase: onHandMl,
      packageSizeBase: bottleMl,
    );
  }

  /// Build a shop pack line from a measured need + catalog purchase spec.
  ShopPackLine? shopLine({
    required String name,
    required double? needQty,
    required String? needUnit,
    required double haveBase,
    required PurchaseSpec purchase,
    String? note,
    int minPackagesIfUnknown = 1,
    int extraSafetyPacks = 0,
  }) {
    final needBase = toCompatibleBase(needQty, needUnit, purchase.sizeUnit);
    if (purchase.hasSize && needBase != null) {
      var packs = packagesToBuy(
        needBase: needBase,
        haveBase: haveBase,
        packageSizeBase: purchase.sizeBase!,
      );
      packs += extraSafetyPacks;
      if (packs <= 0) return null;
      return ShopPackLine(
        name: name,
        packages: packs,
        unitLabel: purchase.unitLabel,
        pricePerPackage: purchase.pricePerUnit,
        needBase: needBase,
        needUnit: purchase.sizeUnit,
        haveBase: haveBase,
        note: note,
      );
    }
    if (haveBase > 0 && needBase != null && needBase <= haveBase && extraSafetyPacks <= 0) {
      return null;
    }
    final packs = (minPackagesIfUnknown < 1 ? 1 : minPackagesIfUnknown) + extraSafetyPacks;
    if (packs <= 0) return null;
    return ShopPackLine(
      name: name,
      packages: packs,
      unitLabel: purchase.unitLabel,
      pricePerPackage: purchase.pricePerUnit,
      needBase: needBase,
      needUnit: needUnit,
      haveBase: haveBase,
      note: note,
    );
  }

  /// Recipe-ingredient need × servings → pack line (dry goods).
  ShopPackLine? lineForRecipeIngredient({
    required RecipeIngredient ingredient,
    required int servings,
    PantryIngredient? pantry,
  }) {
    if (ingredient.isGarnish || ingredient.isOptional) return null;
    final purchase = pantry != null
        ? PurchaseSpec.fromPantry(pantry)
        : const PurchaseSpec(noun: 'pack');
    final have = pantry == null
        ? 0.0
        : (pantryOnHandBase(pantry, needUnit: ingredient.unit) ?? 0);
    final needQty = ingredient.quantity == null
        ? null
        : ingredient.quantity! * servings;
    return shopLine(
      name: ingredient.name,
      needQty: needQty,
      needUnit: ingredient.unit,
      haveBase: have,
      purchase: purchase,
    );
  }

  /// Pack-based recipe cost (never pack-price × servings).
  double? recipePackCost({
    required List<RecipeIngredient> ingredients,
    required List<PantryIngredient> pantry,
    required int servings,
  }) {
    final byName = {
      for (final p in pantry) p.name.toLowerCase().trim(): p,
    };
    double sum = 0;
    var any = false;
    for (final i in ingredients) {
      if (i.isGarnish || i.isOptional) continue;
      final line = lineForRecipeIngredient(
        ingredient: i,
        servings: servings,
        pantry: byName[i.name.toLowerCase().trim()],
      );
      final est = line?.lineEstimate;
      if (est != null) {
        sum += est;
        any = true;
      }
    }
    return any ? sum : null;
  }

  /// Trip-weight label for a protein order (`2.4kg`, `900g`).
  String tripWeightLabel(double? qty, String? unit) {
    final base = toCompatibleBase(qty, unit, 'g');
    if (base == null) return unit ?? 'kg';
    if (base >= 1000) {
      final kg = base / 1000;
      return kg == kg.roundToDouble()
          ? '${kg.round()}kg'
          : '${kg.toStringAsFixed(1)}kg';
    }
    return '${base == base.roundToDouble() ? base.round() : base.toStringAsFixed(0)}g';
  }

  /// Parse a shopping unit that is actually a trip weight (`2.4kg`) so
  /// mark-bought can increment on-hand by the ordered amount, not one SKU.
  double? measureFromLabel(String? raw, {String? targetUnit}) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = _parsePurchaseLabel(raw);
    if (parsed?.sizeBase == null) return null;
    return toCompatibleBase(parsed!.sizeBase, parsed.sizeUnit, targetUnit);
  }

  /// Preferred drinks → pack lines (need one SKU unless already on hand).
  List<ShopPackLine> preferredDrinkPacks({
    required List<String> preferredNames,
    required List<BarIngredient> bar,
    Map<String, int> safetyByName = const {},
  }) {
    final lines = <ShopPackLine>[];
    final seen = <String>{};
    for (final raw in preferredNames) {
      final match = _matchBar(raw, bar);
      if (match == null) continue;
      final key = match.name.toLowerCase().trim();
      if (!seen.add(key)) continue;
      final purchase = PurchaseSpec.fromBar(match);
      final have = barOnHandBase(match, needUnit: purchase.sizeUnit) ?? 0;
      final need = purchase.sizeBase ?? 1;
      final safety = safetyByName[key] ?? 0;
      final line = shopLine(
        name: match.name,
        needQty: need,
        needUnit: purchase.sizeUnit ?? 'ml',
        haveBase: have,
        purchase: purchase,
        extraSafetyPacks: safety,
      );
      if (line != null) lines.add(line);
    }
    return lines;
  }

  BarIngredient? _matchBar(String name, List<BarIngredient> bar) {
    final n = name.toLowerCase().trim();
    if (n.isEmpty) return null;
    for (final b in bar) {
      if (b.name.toLowerCase().trim() == n) return b;
    }
    for (final b in bar) {
      final bn = b.name.toLowerCase().trim();
      if (n.contains(bn) || bn.contains(n)) return b;
    }
    return null;
  }
}
