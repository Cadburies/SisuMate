import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/saildocs_query_service.dart';

/// #245: saildocs query builder — pure functions, no I/O. Syntax confirmed
/// against saildocs.com/gribinfo before implementing (not assumed).
void main() {
  group('buildSaildocsQuery', () {
    test('formats a bounding box with correct N/S/E/W signs and ascending '
        'south->north, west->east order', () {
      final query = buildSaildocsQuery(const SaildocsQueryParams(
        latMin: 40,
        latMax: 60,
        lonMin: -140,
        lonMax: -120,
        latResolution: 1,
        lonResolution: 1,
        forecastHours: [24, 48, 72],
        parameters: ['WIND'],
      ));
      expect(query, 'send gfs:40N,60N,140W,120W|1,1|24,48,72|WIND');
    });

    test('southern/western hemisphere bounds get S/W suffixes', () {
      final query = buildSaildocsQuery(const SaildocsQueryParams(
        latMin: -20,
        latMax: -10,
        lonMin: 150,
        lonMax: 170,
        forecastHours: [24],
        parameters: ['WIND'],
      ));
      expect(query, contains('20S,10S,150E,170E'));
    });

    test('a fractional resolution (e.g. 0.5) is kept, a whole one drops '
        'the trailing .0', () {
      final query = buildSaildocsQuery(const SaildocsQueryParams(
        latMin: 0,
        latMax: 1,
        lonMin: 0,
        lonMax: 1,
        latResolution: 0.5,
        lonResolution: 2,
        forecastHours: [24],
        parameters: ['WIND'],
      ));
      expect(query, contains('|0.5,2|'));
    });

    test('multiple parameters are comma-joined in the given order', () {
      final query = buildSaildocsQuery(const SaildocsQueryParams(
        latMin: 0,
        latMax: 1,
        lonMin: 0,
        lonMax: 1,
        forecastHours: [24],
        parameters: ['WIND', 'WAVES', 'PRMSL'],
      ));
      expect(query, endsWith('WIND,WAVES,PRMSL'));
    });

    test('the query always starts with "send gfs:" (v1 scope: GFS + '
        'one-time request only)', () {
      final query = buildSaildocsQuery(const SaildocsQueryParams(
        latMin: 0,
        latMax: 1,
        lonMin: 0,
        lonMax: 1,
        forecastHours: [24],
      ));
      expect(query, startsWith('send gfs:'));
    });
  });

  group('buildSaildocsMailtoUri', () {
    test('targets query@saildocs.com with the query text in the body, not '
        'the subject', () {
      final uri = buildSaildocsMailtoUri('send gfs:40N,60N,140W,120W|1,1|24|WIND');
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'query@saildocs.com');
      expect(uri.queryParameters['body'],
          'send gfs:40N,60N,140W,120W|1,1|24|WIND');
      expect(uri.queryParameters.containsKey('subject'), isFalse);
    });

    test('special characters in the query survive URI encoding round-trip',
        () {
      const query = 'send gfs:40N,60N,140W,120W|0.5,0.5|6,12..96|WIND,WAVES';
      final uri = buildSaildocsMailtoUri(query);
      expect(uri.queryParameters['body'], query);
    });
  });
}
