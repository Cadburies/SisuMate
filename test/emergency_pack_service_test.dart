import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/emergency_pack_service.dart';

void main() {
  group('EmergencyPackService (#297)', () {
    final now = DateTime.utc(2026, 8, 1);

    test('expiry math: soon / expired / far', () {
      final docs = [
        Document()
          ..title = 'Passport'
          ..type = 'ID'
          ..expiry = DateTime.utc(2026, 7, 1),
        Document()
          ..title = 'Insurance'
          ..type = 'Insurance'
          ..expiry = DateTime.utc(2026, 8, 20),
        Document()
          ..title = 'Radio'
          ..type = 'License'
          ..expiry = DateTime.utc(2027, 1, 1),
      ];
      final exp = EmergencyPackService.expiringDocuments(docs, now: now);
      expect(exp.map((e) => e.document.title), ['Passport', 'Insurance']);
      expect(exp.first.expired, isTrue);
      expect(exp[1].daysUntilExpiry, 19);
    });

    test('build includes ICE and doc lines', () {
      final crew = [
        CrewMember()
          ..name = 'Alex'
          ..role = 'Skipper'
          ..iceContact = 'Sam +1 555',
        CrewMember()..name = 'NoICE',
      ];
      final docs = [
        Document()
          ..title = 'Passport'
          ..type = 'ID'
          ..expiry = DateTime.utc(2026, 8, 10),
      ];
      final pack = EmergencyPackService.build(
        crew: crew,
        documents: docs,
        now: now,
      );
      expect(pack.hasContent, isTrue);
      expect(pack.lines.any((l) => l.contains('Alex')), isTrue);
      expect(pack.lines.any((l) => l.contains('Passport')), isTrue);
    });
  });
}
