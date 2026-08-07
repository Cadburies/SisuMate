import '../core/units.dart';
import '../models/models.dart';

/// #310 — catalog purchase package (how the item is sold at the shop).
///
/// Distinct from recipe **need** (g/ml) and boat **stock** (on-hand base).
class PurchaseSpec {
  /// Measure inside one SKU in a metric base unit (`ml` or `g`), when known.
  final double? sizeBase;
  final String? sizeUnit;

  /// Human purchase noun for UI / shopping unit field (bottle, bag, pack…).
  final String unitLabel;

  /// Shelf price for **one** purchase unit (not per ml/g).
  final double? pricePerUnit;

  const PurchaseSpec({
    this.sizeBase,
    this.sizeUnit,
    required this.unitLabel,
    this.pricePerUnit,
  });

  bool get hasSize =>
      sizeBase != null && sizeBase! > 0 && sizeUnit != null && sizeUnit!.isNotEmpty;

  /// Build from pantry/bar catalog fields (seed + user edits).
  ///
  /// - [packageQty]/[packageUnit]: seed package size (e.g. 250 + `ml`)
  /// - [priceUnit]: human pack label (`250ml bottle`, `500g pack`, `750ml`)
  /// - [price]: price of one pack
  factory PurchaseSpec.fromCatalog({
    double? packageQty,
    String? packageUnit,
    String? priceUnit,
    double? price,
  }) {
    final label = _purchaseLabel(priceUnit, packageQty, packageUnit);
    final fromPrice = _parseSizeFromPriceUnit(priceUnit);
    if (fromPrice != null) {
      return PurchaseSpec(
        sizeBase: fromPrice.$1,
        sizeUnit: fromPrice.$2,
        unitLabel: label,
        pricePerUnit: price,
      );
    }
    final metric = UnitConverter.toMetric(packageQty, packageUnit);
    if (metric != null &&
        packageQty != null &&
        packageQty > 0 &&
        (metric.unit == 'ml' || metric.unit == 'g' || metric.unit == 'kg')) {
      final size = metric.unit == 'kg' ? metric.quantity * 1000 : metric.quantity;
      final unit = metric.unit == 'kg' ? 'g' : metric.unit;
      return PurchaseSpec(
        sizeBase: size,
        sizeUnit: unit,
        unitLabel: label,
        pricePerUnit: price,
      );
    }
    return PurchaseSpec(unitLabel: label, pricePerUnit: price);
  }

  factory PurchaseSpec.fromPantry(PantryIngredient p) => PurchaseSpec.fromCatalog(
        packageQty: p.quantity,
        packageUnit: p.unit,
        priceUnit: p.lastKnownPriceUnit,
        price: p.lastKnownPrice,
      );

  factory PurchaseSpec.fromBar(BarIngredient b) => PurchaseSpec.fromCatalog(
        packageQty: null,
        packageUnit: null,
        priceUnit: b.lastKnownPriceUnit,
        price: b.lastKnownPrice,
      );
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
    final pack = packages <= 1
        ? '1 × $unitLabel'
        : '$packages × $unitLabel';
    final needPart = needBase != null && needUnit != null
        ? ' (need ${_fmt(needBase!)} $needUnit'
            '${haveBase != null ? ', have ${_fmt(haveBase!)} $needUnit' : ''})'
        : '';
    return '$name — $pack$needPart';
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}

/// #310 — pure conversion between need / stock / purchase packs.
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
    final m = UnitConverter.toMetric(qty, unit);
    if (m == null) return null;
    final t = UnitConverter.toMetric(1, targetUnit ?? m.unit);
    if (t == null) return m.quantity;
    // Align kg→g, L→ml when factors known
    if (m.unit == t.unit) return m.quantity;
    if (m.unit == 'kg' && t.unit == 'g') return m.quantity * 1000;
    if (m.unit == 'g' && t.unit == 'kg') return m.quantity / 1000;
    if (m.unit == 'l' && t.unit == 'ml') return m.quantity * 1000;
    if (m.unit == 'ml' && t.unit == 'l') return m.quantity / 1000;
    // tbsp/tsp already to ml via toMetric
    if (m.unit == 'ml' && (t.unit == 'ml' || targetUnit == null)) return m.quantity;
    if (m.unit == 'g' && (t.unit == 'g' || targetUnit == null)) return m.quantity;
    return null;
  }

  /// On-hand stock for pantry: 0 if not stocked; else convertible quantity.
  ///
  /// Seeded [PantryIngredient.quantity] is catalog **package size** when the
  /// item is not in My Pantry. Once [inMyPantry] is true, the same field is
  /// treated as **on-hand** measure (user can edit). If stocked with no
  /// convertible amount, returns null (unknown — not treated as full cover).
  double? pantryOnHandBase(PantryIngredient p, {String? needUnit}) {
    if (!p.inMyPantry) return 0;
    if (p.quantity == null) return null;
    final base = toCompatibleBase(p.quantity, p.unit, needUnit);
    return base;
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
  }) {
    final needBase = toCompatibleBase(needQty, needUnit, purchase.sizeUnit);
    if (purchase.hasSize && needBase != null) {
      final packs = packagesToBuy(
        needBase: needBase,
        haveBase: haveBase,
        packageSizeBase: purchase.sizeBase!,
      );
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
    // No package size: buy at least one pack if need unknown or have is zero.
    if (haveBase > 0 && needBase != null && needBase <= haveBase) return null;
    final packs = minPackagesIfUnknown < 1 ? 1 : minPackagesIfUnknown;
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
}

// ── parsing helpers ─────────────────────────────────────────────────────────

String _purchaseLabel(String? priceUnit, double? qty, String? unit) {
  final pu = priceUnit?.trim() ?? '';
  if (pu.isNotEmpty) {
    // Prefer the human pack string as the shopping unit label.
    return pu;
  }
  if (qty != null && unit != null && unit.isNotEmpty) {
    final q = qty == qty.roundToDouble() ? qty.round().toString() : qty.toString();
    return '$q $unit pack';
  }
  return 'pack';
}

/// Parse sizes like `250ml bottle`, `500g pack`, `750ml`, `1L bottle`.
(double, String)? _parseSizeFromPriceUnit(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim().toLowerCase().replaceAll(' ', '');
  // 12x200ml case → total 2400 ml
  final caseMatch = RegExp(r'^(\d+)x(\d+(?:\.\d+)?)(ml|l|g|kg)').firstMatch(s);
  if (caseMatch != null) {
    final n = double.parse(caseMatch.group(1)!);
    final each = double.parse(caseMatch.group(2)!);
    final u = caseMatch.group(3)!;
    return _normalizeSize(n * each, u);
  }
  final m = RegExp(r'^(\d+(?:\.\d+)?)(ml|l|g|kg)\b').firstMatch(s);
  if (m != null) {
    return _normalizeSize(double.parse(m.group(1)!), m.group(2)!);
  }
  return null;
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
