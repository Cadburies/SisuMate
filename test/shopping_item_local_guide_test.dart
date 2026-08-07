import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/shopping_item_local_guide.dart';

/// #317 offline shopping guide.
void main() {
  test('formatForItem includes name, store hints, and customs pack', () {
    final item = ShoppingItem()
      ..name = 'DJI mini drone'
      ..quantity = 1
      ..origin = 'spares'
      ..lastPurchasePlace = 'Chandlery';

    final text = ShoppingItemLocalGuide.formatForItem(item);

    expect(text, contains('DJI mini drone'));
    expect(text, contains('Chandlery'));
    expect(text, contains('Where to look'));
    expect(text, contains('Drones often restricted'));
    expect(text, contains('Offline shopping guide'));
  });

  test('localNameHints maps sugar to multi-language aliases', () {
    final hints = ShoppingItemLocalGuide.localNameHints('Brown sugar 1kg');
    expect(hints, isNotEmpty);
    expect(hints.first.toLowerCase(), contains('şeker'));
  });

  test('storeHintsForOrigin pantry vs spares differ', () {
    final pantry = ShoppingItemLocalGuide.storeHintsForOrigin('pantry');
    final spares = ShoppingItemLocalGuide.storeHintsForOrigin('spares');
    expect(pantry.any((s) => s.toLowerCase().contains('supermarket')), isTrue);
    expect(spares.any((s) => s.toLowerCase().contains('chandlery')), isTrue);
  });
}
