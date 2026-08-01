import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/barcode_service.dart';

void main() {
  group('BarcodeService.lookup', () {
    test('returns a match for a known barcode', () {
      final match = BarcodeService.lookup('080480010000');
      expect(match, isNotNull);
      expect(match!.bottleName, 'Bacardi Superior');
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
      expect(match!.bottleName, 'Bacardi Superior');
    });

    test('strips hyphens and non-digits', () {
      final match = BarcodeService.lookup('080-48001-0000');
      expect(match, isNotNull);
      expect(match!.bottleName, 'Bacardi Superior');
    });

    test('matches EAN-13 form with leading zero of a UPC-A entry', () {
      final match = BarcodeService.lookup('0080480010000');
      expect(match, isNotNull);
      expect(match!.suggestedIngredientName, 'White Blended Rum');
    });

    test('a bitters entry resolves with its own category and ABV', () {
      final match = BarcodeService.lookup('036872010016');
      expect(match, isNotNull);
      expect(match!.category, 'bitters');
      expect(match.suggestedIngredientName, 'Angostura Bitters');
      expect(match.abv, 44.7);
    });

    test('ML2: vermouth maps to wine category + seed name', () {
      final match = BarcodeService.lookup('080480300001');
      expect(match, isNotNull);
      expect(match!.category, 'wine');
      expect(match.suggestedIngredientName, 'Sweet Vermouth');
      expect(match.abv, 15.0);
    });

    test('ML2: syrup maps to syrup category', () {
      final match = BarcodeService.lookup('070847811015');
      expect(match, isNotNull);
      expect(match!.category, 'syrup');
      expect(match.suggestedIngredientName, 'Orgeat');
      expect(match.abv, isNull);
    });

    test('ML2: juice maps to juice category', () {
      final match = BarcodeService.lookup('041800002012');
      expect(match, isNotNull);
      expect(match!.category, 'juice');
      expect(match.suggestedIngredientName, 'Fresh Lime Juice');
    });

    test('ML2: mixer maps to mixer category', () {
      final match = BarcodeService.lookup('078000006010');
      expect(match, isNotNull);
      expect(match!.category, 'mixer');
      expect(match.suggestedIngredientName, 'Ginger Beer');
    });

    test('ML2: liqueur expansion (Baileys) uses seed ingredient name', () {
      final match = BarcodeService.lookup('080480250201');
      expect(match, isNotNull);
      expect(match!.category, 'liqueur');
      expect(match.suggestedIngredientName, 'Baileys Irish Cream');
    });

    test('ML2: catalog is substantially larger than the original ~35 spirits', () {
      expect(BarcodeService.catalogSize, greaterThanOrEqualTo(100));
    });
  });
}
