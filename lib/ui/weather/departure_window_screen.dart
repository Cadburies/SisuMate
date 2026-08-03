import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/units.dart';
import '../../providers/passage_readiness_provider.dart' show cachedWeatherProvider;
import '../../services/departure_window_scorer.dart';

/// #232: highlights the best upcoming window(s) to depart within the
/// already-fetched forecast, against simple user thresholds — deterministic,
/// offline, no LLM/BYOK involved. Reads BAI1's cached-weather-only provider
/// (same one #219's briefing uses) — never triggers a network fetch of its
/// own; open Weather and load a forecast first to populate it.
class DepartureWindowScreen extends ConsumerStatefulWidget {
  const DepartureWindowScreen({super.key});

  @override
  ConsumerState<DepartureWindowScreen> createState() =>
      _DepartureWindowScreenState();
}

class _DepartureWindowScreenState extends ConsumerState<DepartureWindowScreen> {
  final _maxWindCtrl = TextEditingController();
  final _maxGustCtrl = TextEditingController();
  final _maxWaveCtrl = TextEditingController();

  @override
  void dispose() {
    _maxWindCtrl.dispose();
    _maxGustCtrl.dispose();
    _maxWaveCtrl.dispose();
    super.dispose();
  }

  double _waveMetersFromInput(double value, DepthUnitPref pref) {
    switch (pref) {
      case DepthUnitPref.meters:
        return value;
      case DepthUnitPref.feet:
        return value * UnitConverter.metersPerFoot;
      case DepthUnitPref.fathoms:
        return value * UnitConverter.metersPerFathom;
    }
  }

  String _waveUnitLabel(DepthUnitPref pref) => switch (pref) {
        DepthUnitPref.meters => 'm',
        DepthUnitPref.feet => 'ft',
        DepthUnitPref.fathoms => 'fm',
      };

  String _fmt(DateTime t) =>
      '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(unitPrefsProvider);
    final weatherAsync = ref.watch(cachedWeatherProvider);

    final maxWindDisplay = double.tryParse(_maxWindCtrl.text.trim());
    final maxGustDisplay = double.tryParse(_maxGustCtrl.text.trim());
    final maxWaveDisplay = double.tryParse(_maxWaveCtrl.text.trim());
    final thresholds = DepartureWindowThresholds(
      maxWindKt: maxWindDisplay == null
          ? null
          : UnitConverter.speedDisplayToKnots(maxWindDisplay, prefs.windSpeed),
      maxGustKt: maxGustDisplay == null
          ? null
          : UnitConverter.speedDisplayToKnots(maxGustDisplay, prefs.windSpeed),
      maxWaveHeightM: maxWaveDisplay == null
          ? null
          : _waveMetersFromInput(maxWaveDisplay, prefs.depth),
    );

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      appBar: AppBar(title: const Text('Departure window planner')),
      body: weatherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not read cached weather: $e')),
        data: (bundle) {
          if (bundle == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No cached weather yet — open Weather and load a '
                  'forecast for this area first.'),
            );
          }
          final windows = scoreDepartureWindows(
            hourly: bundle.hourly,
            marine: bundle.marine,
            thresholds: thresholds,
          );
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text('Thresholds',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SisuColors.getTextPrimaryColor(isDark))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maxWindCtrl,
                      decoration: InputDecoration(
                        labelText:
                            'Max wind (${UnitConverter.speedUnitLabel(prefs.windSpeed)})',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxGustCtrl,
                      decoration: InputDecoration(
                        labelText:
                            'Max gust (${UnitConverter.speedUnitLabel(prefs.windSpeed)})',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxWaveCtrl,
                decoration: InputDecoration(
                  labelText: 'Max wave height (${_waveUnitLabel(prefs.depth)})',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text('Windows',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SisuColors.getTextPrimaryColor(isDark))),
              const SizedBox(height: 8),
              if (windows.isEmpty)
                Text('No forecast windows available.',
                    style: TextStyle(
                        color: SisuColors.getTextSecondaryColor(isDark)))
              else
                ...windows.map((w) => _windowTile(w, isDark)),
            ],
          );
        },
      ),
    );
  }

  Widget _windowTile(DepartureWindow w, bool isDark) {
    return Card(
      color: SisuColors.getTileColor(isDark),
      child: ListTile(
        leading: Icon(
          w.clearsThresholds ? Icons.check_circle : Icons.warning_amber,
          color: w.clearsThresholds ? Colors.green : Colors.orange,
        ),
        title: Text('${_fmt(w.start)} – ${_fmt(w.end)}'),
        subtitle: Text(
          w.clearsThresholds
              ? 'Clears all thresholds'
              : w.breachReasons.join(', '),
        ),
      ),
    );
  }
}
