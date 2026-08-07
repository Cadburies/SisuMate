import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/log_entry_local_parse.dart';

void main() {
  test('extracts wind speed, direction, sog, and weather keywords', () {
    final e = LogEntryLocalParse.parse(
      'Around 0800 motored past the point, 12kt SW breeze, SOG 5.2, '
      'cloudy with light chop. Saw dolphins.',
    );
    expect(e.windSpeedKt, 12);
    expect(e.windDir, 'SW');
    expect(e.sogKt, closeTo(5.2, 0.01));
    expect(e.weather, contains('cloudy'));
    expect(e.notes, contains('dolphins'));
    expect(e.logTime, isNotNull);
    expect(LogEntryLocalParse.hasStructuredFields(e), isTrue);
  });

  test('parses lat/lon N/W', () {
    final e = LogEntryLocalParse.parse('Position 12.05N 61.75W light airs');
    expect(e.positionLat, closeTo(12.05, 0.001));
    expect(e.positionLng, closeTo(-61.75, 0.001));
  });

  test('empty text yields empty entry', () {
    final e = LogEntryLocalParse.parse('   ');
    expect(e.notes, isNull);
    expect(LogEntryLocalParse.hasStructuredFields(e), isFalse);
  });
}
