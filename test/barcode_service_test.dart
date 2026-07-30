import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/barcode_service.dart';

void main() {
  group('BarcodeService.lookup', () {
    test('returns a match for a known barcode', () {
      final match = BarcodeService.lookup('080480010000');
      expect(match, isNotNull);
      expect(match!.bottleName, "Bacardí Superior");
      expect(match.category, 'spirit');
      expect(match.suggestedIngredientName, 'White Blended Rum');
      expect(match.abv, 40.0);
    });

    test('returns null for an unknown barcode', () {
      expect(BarcodeService.lookup('000000000000'), isNull);
    });

    test('trims whitespace before lookup', () {
      final match = BarcodeService.lookup(' 080480010000 ');
      expect(match, isNotNull);
      expect(match!.bottleName, "Bacardí Superior");
    });

    test('a bitters entry resolves with its own category and ABV', () {
      final match = BarcodeService.lookup('036872010016');
      expect(match, isNotNull);
      expect(match!.category, 'bitters');
      expect(match.suggestedIngredientName, 'Angostura Bitters');
      expect(match.abv, 44.7);
    });
  });
}
