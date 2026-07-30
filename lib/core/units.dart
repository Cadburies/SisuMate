import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'di.dart';

/// App unit preference. Storage is always metric; this only affects UI and
/// import/export conversion.
enum UnitSystem { metric, imperial }

/// A quantity + unit pair after conversion (or unchanged if unknown).
class MeasuredAmount {
  final double quantity;
  final String unit;
  const MeasuredAmount(this.quantity, this.unit);

  @override
  String toString() => '${UnitConverter.formatNumber(quantity)} $unit';
}

/// Metric-first unit conversion for recipes, fuel, and free-text temperatures.
///
/// Rules:
/// - Database / seed / sync values are always metric (ml, L, g, kg, cm, m, °C).
/// - Imperial UI displays convert on the way out; imperial imports convert on
///   the way in.
/// - Count / qualitative units (dash, piece, clove, whole, …) pass through.
class UnitConverter {
  UnitConverter._();

  // ── Culinary / bar factors (US customary, stored as metric) ──────────────
  static const double mlPerTsp = 5;
  static const double mlPerTbsp = 15;
  static const double mlPerCup = 240;
  /// US legal fluid ounce (import / precise conversion).
  static const double mlPerFlOz = 29.5735;
  /// Bar jigger ounce used for **display** of cocktail pours (30 ml = 1 oz).
  static const double mlPerBarOz = 30;
  static const double mlPerPint = 473.176;
  static const double mlPerQuart = 946.353;
  static const double mlPerGallon = 3785.41;
  static const double gPerOz = 28.3495;
  static const double gPerLb = 453.592;
  static const double cmPerInch = 2.54;
  static const double cmPerFoot = 30.48;
  static const double litersPerGallon = 3.78541;

  /// Canonical metric unit aliases → short form used in storage.
  static const Map<String, String> _metricCanonical = {
    'milliliter': 'ml',
    'milliliters': 'ml',
    'millilitre': 'ml',
    'millilitres': 'ml',
    'liter': 'L',
    'liters': 'L',
    'litre': 'L',
    'litres': 'L',
    'l': 'L',
    'gram': 'g',
    'grams': 'g',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'centimeter': 'cm',
    'centimeters': 'cm',
    'centimetre': 'cm',
    'centimetres': 'cm',
    'meter': 'm',
    'meters': 'm',
    'metre': 'm',
    'metres': 'm',
    'celsius': '°C',
    'c': '°C',
    '°c': '°C',
  };

  /// Imperial / US culinary volume & weight → metric (multiplier, metric unit).
  /// `oz` is treated as **fluid ounces → ml** (cocktail/bar convention). Use
  /// `oz wt` / `ounce weight` for avoirdupois ounces → g.
  static const Map<String, (double, String)> _toMetricFactors = {
    'tsp': (mlPerTsp, 'ml'),
    'tsps': (mlPerTsp, 'ml'),
    'teaspoon': (mlPerTsp, 'ml'),
    'teaspoons': (mlPerTsp, 'ml'),
    'tbsp': (mlPerTbsp, 'ml'),
    'tbsps': (mlPerTbsp, 'ml'),
    'tablespoon': (mlPerTbsp, 'ml'),
    'tablespoons': (mlPerTbsp, 'ml'),
    'cup': (mlPerCup, 'ml'),
    'cups': (mlPerCup, 'ml'),
    'fl oz': (mlPerFlOz, 'ml'),
    'floz': (mlPerFlOz, 'ml'),
    'fluid ounce': (mlPerFlOz, 'ml'),
    'fluid ounces': (mlPerFlOz, 'ml'),
    'oz': (mlPerFlOz, 'ml'),
    'ounce': (mlPerFlOz, 'ml'),
    'ounces': (mlPerFlOz, 'ml'),
    'oz wt': (gPerOz, 'g'),
    'oz weight': (gPerOz, 'g'),
    'ounce weight': (gPerOz, 'g'),
    'pint': (mlPerPint, 'ml'),
    'pints': (mlPerPint, 'ml'),
    'pt': (mlPerPint, 'ml'),
    'quart': (mlPerQuart, 'ml'),
    'quarts': (mlPerQuart, 'ml'),
    'qt': (mlPerQuart, 'ml'),
    'gallon': (mlPerGallon, 'ml'),
    'gallons': (mlPerGallon, 'ml'),
    'gal': (mlPerGallon, 'ml'),
    'lb': (gPerLb, 'g'),
    'lbs': (gPerLb, 'g'),
    'pound': (gPerLb, 'g'),
    'pounds': (gPerLb, 'g'),
    'inch': (cmPerInch, 'cm'),
    'inches': (cmPerInch, 'cm'),
    'in': (cmPerInch, 'cm'),
    '"': (cmPerInch, 'cm'),
    'foot': (cmPerFoot, 'cm'),
    'feet': (cmPerFoot, 'cm'),
    'ft': (cmPerFoot, 'cm'),
    'fahrenheit': (1, '°C'), // special-cased in convert
    'f': (1, '°C'),
    '°f': (1, '°C'),
  };

  /// Normalize unit string for lookup (lowercase, collapse spaces, strip dots).
  static String normalizeUnit(String unit) {
    var u = unit.trim().toLowerCase().replaceAll('.', '');
    u = u.replaceAll(RegExp(r'\s+'), ' ');
    // "fl. oz" / "fl-oz"
    u = u.replaceAll('-', ' ');
    if (u == 'fl oz' || u == 'fluid oz') return 'fl oz';
    return u;
  }

  /// True when [unit] is a known convertible (or already metric) measurement.
  static bool isConvertible(String? unit) {
    if (unit == null || unit.isEmpty) return false;
    final n = normalizeUnit(unit);
    return _toMetricFactors.containsKey(n) ||
        _metricCanonical.containsKey(n) ||
        const {'ml', 'g', 'kg', 'cm', 'm', 'l', '°c'}.contains(n);
  }

  /// Convert quantity+unit to canonical metric storage.
  /// Unknown / count units pass through unchanged. Null [quantity] keeps null
  /// and only canonicalizes the unit when it is a known measurement unit.
  static MeasuredAmount? toMetric(double? quantity, String? unit) {
    if (unit == null || unit.isEmpty) {
      if (quantity == null) return null;
      return MeasuredAmount(quantity, '');
    }
    final n = normalizeUnit(unit);

    String canonicalUnit() {
      if (n == 'f' || n == '°f' || n == 'fahrenheit') return '°C';
      if (n == 'c' || n == '°c' || n == 'celsius') return '°C';
      final factor = _toMetricFactors[n];
      if (factor != null) return factor.$2;
      final metric = _metricCanonical[n];
      if (metric != null) return metric;
      if (n == 'ml') return 'ml';
      if (n == 'g') return 'g';
      if (n == 'kg') return 'kg';
      if (n == 'cm') return 'cm';
      if (n == 'm') return 'm';
      return unit;
    }

    if (quantity == null) {
      return MeasuredAmount(0, canonicalUnit());
    }

    // Temperature special case
    if (n == 'f' || n == '°f' || n == 'fahrenheit') {
      return MeasuredAmount(_fToC(quantity), '°C');
    }
    if (n == 'c' || n == '°c' || n == 'celsius') {
      return MeasuredAmount(quantity, '°C');
    }

    final factor = _toMetricFactors[n];
    if (factor != null) {
      return MeasuredAmount(_roundNice(quantity * factor.$1), factor.$2);
    }

    final metric = _metricCanonical[n];
    if (metric != null) {
      return MeasuredAmount(quantity, metric);
    }

    // Already short metric or unknown (dash, piece, …)
    if (n == 'ml') return MeasuredAmount(quantity, 'ml');
    if (n == 'g') return MeasuredAmount(quantity, 'g');
    if (n == 'kg') return MeasuredAmount(quantity, 'kg');
    if (n == 'cm') return MeasuredAmount(quantity, 'cm');
    if (n == 'm') return MeasuredAmount(quantity, 'm');
    return MeasuredAmount(quantity, unit);
  }

  /// Convert a metric-stored amount for display in [system].
  ///
  /// When [preferBarUnits] is true (cocktails), ml is shown as jigger **oz**
  /// (30 ml = 1 oz) with quarter-oz snapping — never tbsp/cup.
  static MeasuredAmount? forDisplay(
    double? quantity,
    String? unit,
    UnitSystem system, {
    bool preferBarUnits = false,
  }) {
    if (quantity == null && (unit == null || unit.isEmpty)) return null;
    // Ensure we start from metric (handles legacy imperial rows).
    final metric = toMetric(quantity, unit);
    if (metric == null) return null;
    if (system == UnitSystem.metric) {
      if (metric.unit.isEmpty) return MeasuredAmount(metric.quantity, '');
      return metric;
    }
    return _metricToImperial(
      metric.quantity,
      metric.unit,
      preferBarUnits: preferBarUnits,
    );
  }

  static MeasuredAmount _metricToImperial(
    double qty,
    String unit, {
    bool preferBarUnits = false,
  }) {
    final n = normalizeUnit(unit);
    switch (n) {
      case 'ml':
        if (preferBarUnits) {
          return _mlToBarOz(qty);
        }
        // Culinary: cups / tbsp / tsp when they land cleanly, else fl oz.
        if (_almostMultiple(qty, mlPerCup) && qty >= mlPerCup * 0.5) {
          return MeasuredAmount(_roundNice(qty / mlPerCup), 'cup');
        }
        if (_almostMultiple(qty, mlPerTbsp) &&
            qty >= mlPerTbsp &&
            qty < mlPerCup) {
          return MeasuredAmount(_roundNice(qty / mlPerTbsp), 'tbsp');
        }
        if (_almostMultiple(qty, mlPerTsp) &&
            qty >= mlPerTsp &&
            qty < mlPerTbsp) {
          return MeasuredAmount(_roundNice(qty / mlPerTsp), 'tsp');
        }
        return MeasuredAmount(_roundNice(qty / mlPerFlOz), 'fl oz');
      case 'l':
        return MeasuredAmount(_roundNice(qty / litersPerGallon), 'gal');
      case 'g':
        if (qty >= gPerLb) {
          return MeasuredAmount(_roundNice(qty / gPerLb), 'lb');
        }
        return MeasuredAmount(_roundNice(qty / gPerOz), 'oz');
      case 'kg':
        return MeasuredAmount(_roundNice(qty * 1000 / gPerLb), 'lb');
      case 'cm':
        if (qty >= cmPerFoot) {
          return MeasuredAmount(_roundNice(qty / cmPerFoot), 'ft');
        }
        return MeasuredAmount(_roundNice(qty / cmPerInch), 'in');
      case 'm':
        return MeasuredAmount(_roundNice(qty * 100 / cmPerFoot), 'ft');
      case '°c':
      case 'c':
        return MeasuredAmount(_roundNice(_cToF(qty)), '°F');
      default:
        return MeasuredAmount(qty, unit);
    }
  }

  /// Map stored ml → bar oz (30 ml = 1 oz), snap to nearest ¼ oz when close.
  static MeasuredAmount _mlToBarOz(double ml) {
    final oz = ml / mlPerBarOz;
    final quarters = (oz * 4).round() / 4.0;
    if ((oz - quarters).abs() < 0.08) {
      return MeasuredAmount(quarters, 'oz');
    }
    return MeasuredAmount(_roundNice(oz), 'oz');
  }

  /// Format quantity+unit for UI (empty if both missing).
  ///
  /// [preferBarUnits]: cocktail pours as `½ oz`, `1 oz`, `1½ oz` (not tbsp).
  static String format(
    double? quantity,
    String? unit,
    UnitSystem system, {
    double scale = 1,
    bool preferBarUnits = false,
  }) {
    final q = quantity == null ? null : quantity * scale;
    final shown = forDisplay(
      q,
      unit,
      system,
      preferBarUnits: preferBarUnits,
    );
    if (shown == null) return '';
    if (shown.unit.isEmpty) {
      return quantity == null ? '' : formatNumber(shown.quantity);
    }
    if (quantity == null) return shown.unit;
    final qtyLabel = preferBarUnits && shown.unit == 'oz'
        ? formatBarOz(shown.quantity)
        : formatNumber(shown.quantity);
    return '$qtyLabel ${shown.unit}';
  }

  /// Bar-style oz: `¼`, `½`, `¾`, `1`, `1¼`, `1½`, `2`…
  static String formatBarOz(double oz) {
    if (oz < 0) return formatNumber(oz);
    final whole = oz.floor();
    final frac = oz - whole;
    String? fracLabel;
    if ((frac - 0.25).abs() < 0.02) {
      fracLabel = '¼';
    } else if ((frac - 0.5).abs() < 0.02) {
      fracLabel = '½';
    } else if ((frac - 0.75).abs() < 0.02) {
      fracLabel = '¾';
    } else if (frac.abs() < 0.02) {
      fracLabel = null;
    } else {
      return formatNumber(oz);
    }
    if (whole == 0) return fracLabel ?? '0';
    if (fracLabel == null) return '$whole';
    return '$whole$fracLabel';
  }

  static String formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    // Trim trailing zeros
    final s = value.toStringAsFixed(2);
    if (s.endsWith('0')) {
      final one = value.toStringAsFixed(1);
      if (one.endsWith('0')) return value.toInt().toString();
      return one;
    }
    return s;
  }

  // ── Fuel volume + unit price (always stored as liters / $/L) ─────────────

  static String fuelVolumeLabel(UnitSystem system) =>
      system == UnitSystem.imperial ? 'gal' : 'L';

  /// Short unit for price labels: "litre" / "gallon".
  static String fuelPriceVolumeWord(UnitSystem system) =>
      system == UnitSystem.imperial ? 'gallon' : 'litre';

  static double litersToDisplay(double liters, UnitSystem system) =>
      system == UnitSystem.imperial
          ? _roundNice(liters / litersPerGallon)
          : liters;

  /// Parse a user-entered volume in the active system → liters for storage.
  static double displayVolumeToLiters(double value, UnitSystem system) =>
      system == UnitSystem.imperial ? value * litersPerGallon : value;

  static String formatLiters(double liters, UnitSystem system) {
    final v = litersToDisplay(liters, system);
    return '${formatNumber(v)} ${fuelVolumeLabel(system)}';
  }

  /// Stored `$/L` → display `$/L` or `$/gal`.
  static double pricePerLiterToDisplay(
    double pricePerLiter,
    UnitSystem system,
  ) =>
      system == UnitSystem.imperial
          ? pricePerLiter * litersPerGallon
          : pricePerLiter;

  /// User-entered `$/L` or `$/gal` → stored `$/L`.
  static double displayPriceToPerLiter(
    double displayPrice,
    UnitSystem system,
  ) =>
      system == UnitSystem.imperial
          ? displayPrice / litersPerGallon
          : displayPrice;

  static String formatPricePerVolume(
    double pricePerLiter,
    UnitSystem system,
  ) {
    final p = pricePerLiterToDisplay(pricePerLiter, system);
    return '\$${p.toStringAsFixed(2)}/${fuelVolumeLabel(system)}';
  }

  // ── Temperature in free text (instructions) ──────────────────────────────

  static final _tempF = RegExp(
    r'(-?\d+(?:\.\d+)?)\s*°?\s*F\b',
    caseSensitive: false,
  );
  static final _tempC = RegExp(
    r'(-?\d+(?:\.\d+)?)\s*°?\s*C\b',
    caseSensitive: false,
  );

  /// Convert °F↔°C markers in prose for the target system.
  static String convertTemperaturesInText(String text, UnitSystem target) {
    if (target == UnitSystem.metric) {
      return text.replaceAllMapped(_tempF, (m) {
        final f = double.tryParse(m.group(1)!);
        if (f == null) return m.group(0)!;
        return '${formatNumber(_fToC(f))}°C';
      });
    }
    return text.replaceAllMapped(_tempC, (m) {
      final c = double.tryParse(m.group(1)!);
      if (c == null) return m.group(0)!;
      return '${formatNumber(_cToF(c))}°F';
    });
  }

  /// Apply toMetric to a quantity/unit pair (import / seed path).
  /// When quantity is null, unit is still canonicalized if convertible.
  static (double?, String?) normalizePair(double? quantity, String? unit) {
    if (quantity == null && (unit == null || unit.isEmpty)) {
      return (null, unit);
    }
    final m = toMetric(quantity, unit);
    if (m == null) return (quantity, unit);
    if (m.unit.isEmpty) return (quantity, unit);
    // toMetric uses 0 as a placeholder when quantity was null — restore null.
    return (quantity == null ? null : m.quantity, m.unit);
  }

  static double _fToC(double f) => (f - 32) * 5 / 9;
  static double _cToF(double c) => c * 9 / 5 + 32;

  static bool _almostMultiple(double value, double base) {
    if (base <= 0) return false;
    final n = value / base;
    return (n - n.round()).abs() < 0.06;
  }

  static double _roundNice(double v) {
    if (v.abs() >= 100) return (v * 10).round() / 10;
    if (v.abs() >= 10) return (v * 10).round() / 10;
    if (v.abs() >= 1) return (v * 100).round() / 100;
    return (v * 1000).round() / 1000;
  }
}

// ── Preference notifier (mirrors ThemeModeNotifier) ──────────────────────────

class UnitSystemNotifier extends Notifier<UnitSystem> {
  @override
  UnitSystem build() => UnitSystem.metric;

  void setMetric() {
    state = UnitSystem.metric;
    _persist(false);
  }

  void setImperial() {
    state = UnitSystem.imperial;
    _persist(true);
  }

  void setSystem(UnitSystem system) {
    state = system;
    _persist(system == UnitSystem.imperial);
  }

  /// Restores persisted preference on startup without writing.
  void restore(bool useImperial) {
    state = useImperial ? UnitSystem.imperial : UnitSystem.metric;
  }

  Future<void> _persist(bool useImperial) async {
    try {
      final settings = await ref.read(userSettingsProvider.future);
      if (settings == null) return;
      settings.useImperial = useImperial;
      await ref.read(userSettingsRepositoryProvider).updateSettings(settings);
    } catch (_) {
      // Best-effort
    }
  }
}

final unitSystemProvider =
    NotifierProvider<UnitSystemNotifier, UnitSystem>(UnitSystemNotifier.new);
