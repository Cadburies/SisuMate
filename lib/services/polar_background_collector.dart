import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/repositories/boat_repository.dart';
import '../domain/repositories/user_settings_repository.dart';
import '../models/models.dart';
import 'boat_instrument_failover_service.dart';
import 'error_log_service.dart';
import 'sailing_polar_collector.dart';

/// #275 — dedicated under-sail polar sample collector that runs while the
/// app is in the **foreground**, without requiring Anchor Alarm to be open.
///
/// Not a true OS background isolate (iOS would kill that for non-nav apps);
/// it is a periodic instrument poll tied to app lifecycle — same practical
/// window as other "while sailing with the app open" features.
class PolarBackgroundCollector with WidgetsBindingObserver {
  PolarBackgroundCollector({
    required this.collector,
    required this.boatRepository,
    required this.settingsRepository,
    this.failover = const BoatInstrumentFailoverService(),
    this.interval = const Duration(seconds: 45),
  });

  final SailingPolarCollector collector;
  final BoatRepository boatRepository;
  final UserSettingsRepository settingsRepository;
  final BoatInstrumentFailoverService failover;
  final Duration interval;

  Timer? _timer;
  bool _tickInFlight = false;
  bool _started = false;

  /// Begin lifecycle observation + periodic ticks.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(interval, (_) => unawaited(tick()));
    // First tick soon after start (don't wait a full interval).
    unawaited(Future<void>.delayed(const Duration(seconds: 5), tick));
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timer ??= Timer.periodic(interval, (_) => unawaited(tick()));
      unawaited(tick());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// One instrument fetch + maybeRecord. Safe to call from tests.
  Future<void> tick() async {
    if (_tickInFlight) return;
    _tickInFlight = true;
    try {
      final boats = await boatRepository.getBoats();
      Boat? boat;
      for (final b in boats) {
        if (b.supabaseId.isNotEmpty) {
          boat = b;
          break;
        }
      }
      boat ??= boats.isNotEmpty ? boats.first : null;
      if (boat == null) return;
      final boatId = boat.supabaseId;
      if (boatId.isEmpty) return;

      final settings = await settingsRepository.getSettings();
      final snap = await failover.fetch(settings: settings);
      final data = snap.boatData;
      if (data == null) return;

      await collector.maybeRecord(
        data: data,
        boatSupabaseId: boatId,
        enginePortRpm: data.enginePortRpm,
        engineStbdRpm: data.engineStbdRpm,
      );
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'polar background tick failed: $e',
        context: 'polar_background_collector: tick',
      ));
    } finally {
      _tickInFlight = false;
    }
  }
}
