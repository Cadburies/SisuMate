import '../core/units.dart';
import 'weather_service.dart';

/// #232: departure-window planner thresholds. Any null threshold is not
/// checked (the user only cares about the ones they set).
class DepartureWindowThresholds {
  final double? maxWindKt;
  final double? maxGustKt;
  final double? maxWaveHeightM;

  const DepartureWindowThresholds({
    this.maxWindKt,
    this.maxGustKt,
    this.maxWaveHeightM,
  });
}

/// A contiguous run of hours sharing the same pass/fail verdict against
/// [DepartureWindowThresholds]. [end] is exclusive (one hour past the last
/// included hour), so [duration] is simple subtraction.
class DepartureWindow {
  final DateTime start;
  final DateTime end;
  final bool clearsThresholds;
  final List<String> breachReasons;

  const DepartureWindow({
    required this.start,
    required this.end,
    required this.clearsThresholds,
    this.breachReasons = const [],
  });

  Duration get duration => end.difference(start);
}

/// #232: scores the already-fetched hourly (+ optional marine) forecast
/// against user thresholds — deterministic, offline, no new network call
/// and no LLM/BYOK involved (`WeatherBundle`/`HourlyWeather`/`HourlyMarine`
/// already carry everything needed). Returns every contiguous window,
/// ranked clearing-windows-first (longest, then earliest), so the caller
/// can show both the best window(s) to leave and which hours to avoid.
List<DepartureWindow> scoreDepartureWindows({
  required List<HourlyWeather> hourly,
  List<HourlyMarine> marine = const [],
  required DepartureWindowThresholds thresholds,
}) {
  if (hourly.isEmpty) return const [];

  final marineByHour = <DateTime, HourlyMarine>{
    for (final m in marine)
      DateTime(m.time.year, m.time.month, m.time.day, m.time.hour): m,
  };

  final windows = <DepartureWindow>[];
  DateTime? runStart;
  bool? runClears;
  var runReasons = <String>{};

  void closeRun(DateTime endExclusive) {
    if (runStart == null) return;
    windows.add(DepartureWindow(
      start: runStart,
      end: endExclusive,
      clearsThresholds: runClears!,
      breachReasons: runReasons.toList()..sort(),
    ));
  }

  for (final h in hourly) {
    final reasons = <String>{};
    if (thresholds.maxWindKt != null && h.windMs != null) {
      final kt = h.windMs! / UnitConverter.msPerKnot;
      if (kt > thresholds.maxWindKt!) {
        reasons.add(
            'wind ${kt.round()}kt > ${thresholds.maxWindKt!.round()}kt max');
      }
    }
    if (thresholds.maxGustKt != null && h.windGustMs != null) {
      final kt = h.windGustMs! / UnitConverter.msPerKnot;
      if (kt > thresholds.maxGustKt!) {
        reasons.add(
            'gust ${kt.round()}kt > ${thresholds.maxGustKt!.round()}kt max');
      }
    }
    if (thresholds.maxWaveHeightM != null) {
      final m = marineByHour[
          DateTime(h.time.year, h.time.month, h.time.day, h.time.hour)];
      if (m?.waveHeightM != null && m!.waveHeightM! > thresholds.maxWaveHeightM!) {
        reasons.add(
            'wave ${m.waveHeightM!.toStringAsFixed(1)}m > ${thresholds.maxWaveHeightM!.toStringAsFixed(1)}m max');
      }
    }
    final clears = reasons.isEmpty;

    if (runStart == null) {
      runStart = h.time;
      runClears = clears;
      runReasons = reasons;
    } else if (runClears == clears) {
      runReasons.addAll(reasons);
    } else {
      closeRun(h.time);
      runStart = h.time;
      runClears = clears;
      runReasons = reasons;
    }
  }
  closeRun(hourly.last.time.add(const Duration(hours: 1)));

  windows.sort((a, b) {
    if (a.clearsThresholds != b.clearsThresholds) {
      return a.clearsThresholds ? -1 : 1;
    }
    final byDuration = b.duration.compareTo(a.duration);
    if (byDuration != 0) return byDuration;
    return a.start.compareTo(b.start);
  });
  return windows;
}
