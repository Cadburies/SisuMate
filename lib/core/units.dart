import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'di.dart';
import '../services/error_log_service.dart';

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

/// Metric-first unit conversion for recipes, fuel, weather, and free-text.
///
/// Rules:
/// - **Database / seed / sync storage are always metric** (ml, L, g, kg, cm, m,
///   m/s, °C, mm, …). Never write gal/°F/kn as stored values for cooking/fuel.
/// - **Display** follows [AppUnitPrefs] (per-category: volume, temp, speed,
///   depth, distance). Presets match common marine apps (Marine / US / Metric).
/// - **Input:** convert display units → metric before store.
/// - Count / qualitative units (dash, piece, clove, whole, ...) pass through.
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

  // ── Weather / marine display (source always metric) ───────────────────────

  static const double metersPerFoot = 0.3048;
  static const double metersPerFathom = 1.8288;
  static const double msPerKnot = 0.514444;
  static const double mmPerInch = 25.4;
  static const double kmPerNm = 1.852;
  static const double miPerNm = 1.15078;

  /// Stored °C → display per [temp] (or legacy [system]).
  static String formatTempC(
    double celsius,
    UnitSystem system, {
    TempUnitPref? temp,
  }) {
    final t = temp ??
        (system == UnitSystem.imperial
            ? TempUnitPref.fahrenheit
            : TempUnitPref.celsius);
    if (t == TempUnitPref.fahrenheit) {
      return '${_cToF(celsius).round()} F';
    }
    return '${celsius.round()} C';
  }

  static String formatTempCRange(
    double? minC,
    double? maxC,
    UnitSystem system, {
    TempUnitPref? temp,
  }) {
    final lo = minC == null ? '-' : formatTempC(minC, system, temp: temp);
    final hi = maxC == null ? '-' : formatTempC(maxC, system, temp: temp);
    return '$lo / $hi';
  }

  /// Wind / boat SOG from stored m/s → preferred speed unit.
  static String formatSpeedFromMs(double ms, SpeedUnitPref unit) {
    switch (unit) {
      case SpeedUnitPref.knots:
        return '${(ms / msPerKnot).round()} kn';
      case SpeedUnitPref.kmh:
        return '${formatNumber(ms * 3.6)} km/h';
      case SpeedUnitPref.mph:
        return '${formatNumber(ms * 2.23694)} mph';
      case SpeedUnitPref.metersPerSecond:
        return '${formatNumber(ms)} m/s';
    }
  }

  /// Boat speed already in knots → display unit (passage planner).
  static String formatSpeedFromKnots(double knots, SpeedUnitPref unit) {
    return formatSpeedFromMs(knots * msPerKnot, unit);
  }

  /// Convert a user-entered boat speed in [unit] → knots (for planPassage).
  static double speedDisplayToKnots(double value, SpeedUnitPref unit) {
    switch (unit) {
      case SpeedUnitPref.knots:
        return value;
      case SpeedUnitPref.kmh:
        return value / 1.852;
      case SpeedUnitPref.mph:
        return value / 1.15078;
      case SpeedUnitPref.metersPerSecond:
        return value / msPerKnot;
    }
  }

  /// Convert knots → display value in [unit].
  static double knotsToSpeedDisplay(double knots, SpeedUnitPref unit) {
    switch (unit) {
      case SpeedUnitPref.knots:
        return knots;
      case SpeedUnitPref.kmh:
        return knots * 1.852;
      case SpeedUnitPref.mph:
        return knots * 1.15078;
      case SpeedUnitPref.metersPerSecond:
        return knots * msPerKnot;
    }
  }

  static String speedUnitLabel(SpeedUnitPref unit) => switch (unit) {
        SpeedUnitPref.knots => 'kn',
        SpeedUnitPref.kmh => 'km/h',
        SpeedUnitPref.mph => 'mph',
        SpeedUnitPref.metersPerSecond => 'm/s',
      };

  /// @deprecated Prefer [formatSpeedFromMs] with [AppUnitPrefs.windSpeed].
  static String formatWindKnotsFromMs(double ms) =>
      formatSpeedFromMs(ms, SpeedUnitPref.knots);

  static String formatKnots(double knots) => '${knots.round()} kn';

  /// Stored meters → depth/wave length in preferred unit.
  static String formatLengthM(
    double meters,
    UnitSystem system, {
    DepthUnitPref? depth,
  }) {
    final d = depth ??
        (system == UnitSystem.imperial
            ? DepthUnitPref.feet
            : DepthUnitPref.meters);
    switch (d) {
      case DepthUnitPref.meters:
        return '${formatNumber(meters)} m';
      case DepthUnitPref.feet:
        return '${formatNumber(meters / metersPerFoot)} ft';
      case DepthUnitPref.fathoms:
        return '${formatNumber(meters / metersPerFathom)} fm';
    }
  }

  /// Passage distance stored as NM → preferred unit.
  static String formatDistanceNm(double nm, DistanceUnitPref unit) {
    switch (unit) {
      case DistanceUnitPref.nauticalMiles:
        return '${formatNumber(nm)} NM';
      case DistanceUnitPref.kilometers:
        return '${formatNumber(nm * kmPerNm)} km';
      case DistanceUnitPref.statuteMiles:
        return '${formatNumber(nm * miPerNm)} mi';
    }
  }

  static String formatPrecipMm(double mm, UnitSystem system) {
    if (system == UnitSystem.imperial) {
      return '${formatNumber(mm / mmPerInch)} in';
    }
    return '${formatNumber(mm)} mm';
  }

  static String? formatChartDepthM(
    double? elevationM,
    UnitSystem system, {
    DepthUnitPref? depth,
  }) {
    if (elevationM == null) return null;
    if (elevationM < 0) {
      return 'Charted depth ~${formatLengthM(-elevationM, system, depth: depth)}';
    }
    return 'Land elev. ~${formatLengthM(elevationM, system, depth: depth)}';
  }

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

// ── Per-category unit preferences (marine-app style) ─────────────────────────

enum VolumeUnitPref { liters, usGallons }

enum TempUnitPref { celsius, fahrenheit }

/// Shared enum for both wind and boat/SOG speed prefs — kept independent
/// (SUG5): most chartplotters tie them together, but some marine apps let
/// wind stay in knots while boat speed shows km/h, or vice versa.
enum SpeedUnitPref { knots, kmh, mph, metersPerSecond }

enum DepthUnitPref { meters, feet, fathoms }

enum DistanceUnitPref { nauticalMiles, kilometers, statuteMiles }

/// Named preset applied as a whole, then user can tweak rows.
enum UnitPreset { marine, us, metric }

/// Full unit profile. **Storage is always metric**; this is display/input only.
class AppUnitPrefs {
  final VolumeUnitPref volume;
  final TempUnitPref temperature;
  final SpeedUnitPref windSpeed;
  final SpeedUnitPref boatSpeed;
  final DepthUnitPref depth;
  final DistanceUnitPref distance;

  const AppUnitPrefs({
    required this.volume,
    required this.temperature,
    required this.windSpeed,
    required this.boatSpeed,
    required this.depth,
    required this.distance,
  });

  /// Default for sailors: metric cooking/fuel/temp, knots, meters, NM.
  static const marine = AppUnitPrefs(
    volume: VolumeUnitPref.liters,
    temperature: TempUnitPref.celsius,
    windSpeed: SpeedUnitPref.knots,
    boatSpeed: SpeedUnitPref.knots,
    depth: DepthUnitPref.meters,
    distance: DistanceUnitPref.nauticalMiles,
  );

  /// US coastal: gallons, F, knots, feet, NM.
  static const us = AppUnitPrefs(
    volume: VolumeUnitPref.usGallons,
    temperature: TempUnitPref.fahrenheit,
    windSpeed: SpeedUnitPref.knots,
    boatSpeed: SpeedUnitPref.knots,
    depth: DepthUnitPref.feet,
    distance: DistanceUnitPref.nauticalMiles,
  );

  /// Land/metric strict: L, C, km/h, m, km (less common at sea).
  static const metric = AppUnitPrefs(
    volume: VolumeUnitPref.liters,
    temperature: TempUnitPref.celsius,
    windSpeed: SpeedUnitPref.kmh,
    boatSpeed: SpeedUnitPref.kmh,
    depth: DepthUnitPref.meters,
    distance: DistanceUnitPref.kilometers,
  );

  UnitSystem get volumeSystem => volume == VolumeUnitPref.usGallons
      ? UnitSystem.imperial
      : UnitSystem.metric;

  UnitSystem get tempSystem => temperature == TempUnitPref.fahrenheit
      ? UnitSystem.imperial
      : UnitSystem.metric;

  /// Matches a named preset, or null if custom mix.
  UnitPreset? get matchingPreset {
    if (this == marine) return UnitPreset.marine;
    if (this == us) return UnitPreset.us;
    if (this == metric) return UnitPreset.metric;
    return null;
  }

  AppUnitPrefs copyWith({
    VolumeUnitPref? volume,
    TempUnitPref? temperature,
    SpeedUnitPref? windSpeed,
    SpeedUnitPref? boatSpeed,
    DepthUnitPref? depth,
    DistanceUnitPref? distance,
  }) =>
      AppUnitPrefs(
        volume: volume ?? this.volume,
        temperature: temperature ?? this.temperature,
        windSpeed: windSpeed ?? this.windSpeed,
        boatSpeed: boatSpeed ?? this.boatSpeed,
        depth: depth ?? this.depth,
        distance: distance ?? this.distance,
      );

  Map<String, dynamic> toJson() => {
        'volume': volume.name,
        'temperature': temperature.name,
        'windSpeed': windSpeed.name,
        'boatSpeed': boatSpeed.name,
        'depth': depth.name,
        'distance': distance.name,
      };

  factory AppUnitPrefs.fromJson(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) return marine;
    T parse<T extends Enum>(List<T> values, String key, T fallback) {
      final name = j[key] as String?;
      if (name == null) return fallback;
      return values.cast<T?>().firstWhere(
            (e) => e!.name == name,
            orElse: () => fallback,
          )!;
    }

    return AppUnitPrefs(
      volume: parse(VolumeUnitPref.values, 'volume', marine.volume),
      temperature:
          parse(TempUnitPref.values, 'temperature', marine.temperature),
      windSpeed: parse(SpeedUnitPref.values, 'windSpeed', marine.windSpeed),
      boatSpeed: parse(SpeedUnitPref.values, 'boatSpeed', marine.boatSpeed),
      depth: parse(DepthUnitPref.values, 'depth', marine.depth),
      distance: parse(DistanceUnitPref.values, 'distance', marine.distance),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUnitPrefs &&
          volume == other.volume &&
          temperature == other.temperature &&
          windSpeed == other.windSpeed &&
          boatSpeed == other.boatSpeed &&
          depth == other.depth &&
          distance == other.distance;

  @override
  int get hashCode =>
      Object.hash(volume, temperature, windSpeed, boatSpeed, depth, distance);
}

// ── Preference notifiers ─────────────────────────────────────────────────────

class UnitPrefsNotifier extends Notifier<AppUnitPrefs> {
  @override
  AppUnitPrefs build() => AppUnitPrefs.marine;

  void restore(AppUnitPrefs prefs) => state = prefs;

  void restoreFromJson(String? unitPrefsJson) {
    if (unitPrefsJson == null || unitPrefsJson.isEmpty) {
      state = AppUnitPrefs.marine;
      return;
    }
    try {
      state = AppUnitPrefs.fromJson(
        jsonDecode(unitPrefsJson) as Map<String, dynamic>,
      );
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'stored unit prefs failed to parse, reset to marine defaults: $e',
        context: 'units: restoreFromJson',
      ));
      state = AppUnitPrefs.marine;
    }
  }

  Future<void> applyPreset(UnitPreset preset) async {
    state = switch (preset) {
      UnitPreset.marine => AppUnitPrefs.marine,
      UnitPreset.us => AppUnitPrefs.us,
      UnitPreset.metric => AppUnitPrefs.metric,
    };
    await _persist();
  }

  Future<void> update(AppUnitPrefs prefs) async {
    state = prefs;
    await _persist();
  }

  Future<void> setVolume(VolumeUnitPref v) async {
    state = state.copyWith(volume: v);
    await _persist();
  }

  Future<void> setTemperature(TempUnitPref t) async {
    state = state.copyWith(temperature: t);
    await _persist();
  }

  Future<void> setWindSpeed(SpeedUnitPref s) async {
    state = state.copyWith(windSpeed: s);
    await _persist();
  }

  Future<void> setBoatSpeed(SpeedUnitPref s) async {
    state = state.copyWith(boatSpeed: s);
    await _persist();
  }

  Future<void> setDepth(DepthUnitPref d) async {
    state = state.copyWith(depth: d);
    await _persist();
  }

  Future<void> setDistance(DistanceUnitPref d) async {
    state = state.copyWith(distance: d);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final settings = await ref.read(userSettingsProvider.future);
      if (settings == null) return;
      settings.unitPrefsJson = jsonEncode(state.toJson());
      await ref.read(userSettingsRepositoryProvider).updateSettings(settings);
    } catch (e) {
      unawaited(ErrorLogService()
          .logWarning('unit prefs failed to persist: $e', context: 'units: _persist'));
    }
  }
}

final unitPrefsProvider =
    NotifierProvider<UnitPrefsNotifier, AppUnitPrefs>(UnitPrefsNotifier.new);

/// Volume/cooking/fuel system derived from [unitPrefsProvider] (not a separate store).
final unitSystemProvider = Provider<UnitSystem>((ref) {
  return ref.watch(unitPrefsProvider).volumeSystem;
});
