import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/boat_instrument_failover_service.dart';
import 'package:sisu_mate/services/boat_position_service.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';

/// #303 — position source labels and result shape.
void main() {
  group('BoatPositionResult', () {
    test('instruments source label uses active source', () {
      final r = BoatPositionResult(
        latitude: 12,
        longitude: -61,
        positionSource: BoatPositionSource.instruments,
        instruments: BoatInstrumentSnapshot(
          boatData: PredictWindBoatData(
            latitude: 12,
            longitude: -61,
            observedAt: DateTime.utc(2026, 8, 1),
          ),
          activeSource: BoatInstrumentSource.dataHubLocal,
          hubStatus: const PredictWindHubStatus(
            PredictWindHubConnectionState.connected,
          ),
        ),
      );
      expect(r.hasPosition, isTrue);
      expect(r.positionSourceLabel, 'DataHub (local)');
    });

    test('phone GPS label is explicit', () {
      final r = BoatPositionResult(
        latitude: 1,
        longitude: 2,
        positionSource: BoatPositionSource.phoneGps,
        instruments: const BoatInstrumentSnapshot(
          boatData: null,
          activeSource: null,
          hubStatus: PredictWindHubStatus(
            PredictWindHubConnectionState.notConfigured,
          ),
        ),
      );
      expect(r.positionSourceLabel, 'Phone GPS');
    });

    test('no position when both paths empty', () {
      const r = BoatPositionResult(
        instruments: BoatInstrumentSnapshot(
          boatData: null,
          activeSource: null,
          hubStatus: PredictWindHubStatus(
            PredictWindHubConnectionState.notConfigured,
          ),
        ),
      );
      expect(r.hasPosition, isFalse);
      expect(r.positionSourceLabel, 'No position');
    });
  });
}
