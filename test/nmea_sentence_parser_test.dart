import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/nmea_sentence_parser.dart';

void main() {
  group('NmeaSentenceParser', () {
    test('parses GGA lat/lon', () {
      final p = NmeaSentenceParser();
      // 48°07.038'N 011°31.000'E — no checksum (parser accepts missing *CS)
      p.feed(r'$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,');
      expect(p.fix.hasPosition, isTrue);
      expect(p.fix.latitude, closeTo(48 + 7.038 / 60, 0.0001));
      expect(p.fix.longitude, closeTo(11 + 31.0 / 60, 0.0001));
    });

    test('parses RMC position + SOG/COG', () {
      final p = NmeaSentenceParser();
      p.feed(
        r'$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W',
      );
      expect(p.fix.hasPosition, isTrue);
      expect(p.fix.sogKt, closeTo(22.4, 0.01));
      expect(p.fix.cogDeg, closeTo(84.4, 0.01));
    });

    test('ignores RMC void status', () {
      final p = NmeaSentenceParser();
      p.feed(
        r'$GPRMC,123519,V,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W',
      );
      expect(p.fix.hasPosition, isFalse);
    });

    test('parses MWV true wind in m/s to knots', () {
      final p = NmeaSentenceParser();
      p.feed(r'$WIMWV,045.0,T,10.0,M,A');
      expect(p.fix.windDirectionDeg, closeTo(45.0, 0.01));
      expect(p.fix.windSpeedKt, closeTo(10.0 * 1.943844, 0.01));
      expect(p.fix.windIsTrue, isTrue);
    });

    test('parses DPT depth', () {
      final p = NmeaSentenceParser();
      p.feed(r'$SDDPT,12.5,0.5,');
      expect(p.fix.depthMeters, closeTo(13.0, 0.01));
    });

    test('rejects bad checksum', () {
      final p = NmeaSentenceParser();
      p.feed(
        r'$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*00',
      );
      expect(p.fix.hasPosition, isFalse);
    });

    test('parses VHW speed through water', () {
      final p = NmeaSentenceParser();
      p.feed(r'$VWVHW,,T,,M,5.5,N,,K');
      expect(p.fix.stwKt, closeTo(5.5, 0.01));
    });

    test('feedLines aggregates multiple sentences', () {
      final p = NmeaSentenceParser();
      p.feedLines(
        r'''
$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,
$WIMWV,090.0,T,12.0,N,A
''',
      );
      expect(p.fix.hasPosition, isTrue);
      expect(p.fix.windSpeedKt, closeTo(12.0, 0.01));
    });
  });
}
