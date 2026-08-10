import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/record_share_service.dart';

bool _isPdf(Uint8List bytes) =>
    bytes.length > 4 &&
    String.fromCharCodes(bytes.sublist(0, 4)) == '%PDF';

void main() {
  group('RecordShareService PDF builders', () {
    test('buildDocumentsPdf produces a valid PDF for selected documents',
        () async {
      final docs = [
        Document()
          ..title = 'Boat Registration'
          ..type = 'Registration'
          ..expiry = DateTime(2027, 6, 1),
        Document()
          ..title = 'Insurance Policy'
          ..type = 'Insurance'
          ..notes = 'Renews every June',
      ];

      final bytes = await RecordShareService.buildDocumentsPdf(docs);
      expect(_isPdf(bytes), isTrue);
    });

    test('buildDocumentsPdf ignores a missing photo path without throwing',
        () async {
      final docs = [
        Document()
          ..title = 'Registration'
          ..type = 'Registration'
          ..localPath = '/nonexistent/path/scan.jpg',
      ];

      final bytes = await RecordShareService.buildDocumentsPdf(docs);
      expect(_isPdf(bytes), isTrue);
    });

    test('buildCrewPdf produces a valid PDF for selected crew', () async {
      final members = [
        CrewMember()
          ..name = 'Skipper Ada'
          ..role = 'Captain'
          ..phone = '+358401234567'
          ..iceContact = 'Next of kin: +358 40 000 0000',
      ];

      final bytes = await RecordShareService.buildCrewPdf(members);
      expect(_isPdf(bytes), isTrue);
    });

    test('#326: buildCrewPdf includes port-entry fields without throwing',
        () async {
      final members = [
        CrewMember()
          ..name = 'Skipper Ada'
          ..role = 'Captain'
          ..dateOfBirth = DateTime(1985, 6, 15)
          ..nationality = 'Finnish'
          ..passportNumber = 'FI1234567',
      ];

      final bytes = await RecordShareService.buildCrewPdf(members);
      expect(_isPdf(bytes), isTrue);
    });

    test('buildInventoryPdf produces a valid PDF for selected items',
        () async {
      final items = [
        InventoryItem()
          ..name = 'Fenders'
          ..location = 'Lazarette'
          ..quantity = 4
          ..unit = 'pcs'
          ..serialNumber = 'SN-99',
      ];

      final bytes = await RecordShareService.buildInventoryPdf(items);
      expect(_isPdf(bytes), isTrue);
    });

    test('builders handle an empty selection without throwing', () async {
      expect(_isPdf(await RecordShareService.buildDocumentsPdf([])), isTrue);
      expect(_isPdf(await RecordShareService.buildCrewPdf([])), isTrue);
      expect(_isPdf(await RecordShareService.buildInventoryPdf([])), isTrue);
    });
  });
}
