import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/shopping_port_run.dart';

void main() {
  ShoppingItem item(String name, {String origin = 'pantry', int qty = 1}) =>
      ShoppingItem()
        ..name = name
        ..origin = origin
        ..quantity = qty
        ..lastPurchasePrice = 6;

  test('offline plan groups pantry vs bar vs marina-desk skip', () {
    final sheet = ShoppingPortRun.planOffline(
      items: [
        item('Beef Tenderloin'),
        item('Carrots'),
        item('Rum', origin: 'bar'),
        item('Propane'),
        item('Bought already')..isBought = true,
      ],
      now: DateTime(2026, 8, 15), // Saturday
    );

    expect(sheet.fromLiveSearch, isFalse);
    expect(sheet.stops.map((s) => s.kind).toList(),
        [ShoppingPortRun.kindSupermarket, ShoppingPortRun.kindLiquor]);
    expect(sheet.stops.first.lines.map((l) => l.name),
        ['Beef Tenderloin', 'Carrots']);
    expect(sheet.stops.last.lines.single.name, 'Rum');
    expect(sheet.skipNotes, isNotEmpty);
    expect(sheet.skipNotes.first, contains('Propane'));
    expect(sheet.tillSummary, contains('priced'));
    expect(sheet.tips.first, contains('Saturday'));
  });

  test('allergen notes use guest first name + catalog tags', () {
    final guest = GuestProfile()
      ..name = 'Marie Curie'
      ..allergenRestrictions = ['nuts'];
    final bar = BarIngredient()
      ..name = 'Orgeat'
      ..allergenTags = ['nuts'];
    final notes = ShoppingPortRun.allergenNotes(
      items: [item('Orgeat', origin: 'bar')],
      guests: [guest],
      pantry: const [],
      bar: [bar],
    );
    expect(notes, ['Marie: Orgeat tagged nuts']);
  });

  test('tryParseLive reads JSON and ignores citation soup', () {
    const raw = '''
Here you go
```json
{"area":"St George's","stops":[{"shop":"Foodland","kind":"supermarket","walk":"10 min from Port Louis","hours":"8-20","till":"EC\$80","items":[{"name":"Beef Tenderloin","say":"fillet"}]}],"skip":["propane — marina"],"allergens":["nuts — skip orgeat"],"tillTotal":"EC\$80","tips":["Go early"]}
```
[[1]](https://example.com)
''';
    final parsed = ShoppingPortRun.tryParseLive(
      raw,
      items: [item('Beef Tenderloin')],
    );
    expect(parsed, isNotNull);
    expect(parsed!.fromLiveSearch, isTrue);
    expect(parsed.area, 'St George\'s');
    expect(parsed.stops.single.shopLabel, 'Foodland');
    expect(parsed.stops.single.walk, contains('Port Louis'));
    expect(parsed.stops.single.lines.single.localName, 'fillet');
    expect(parsed.allergenNotes, ['nuts — skip orgeat']);
  });

  test('tryParseLive returns null for unusable prose', () {
    expect(
      ShoppingPortRun.tryParseLive('**Country Cold Store** [[1]](https://x)',
          items: [item('Beef Tenderloin')]),
      isNull,
    );
  });

  test('cleanProse strips markdown citation junk', () {
    final cleaned = ShoppingPortRun.cleanProse(
      '**Foodland**[[1]](https://x.com) [2](https://y.com)',
    );
    expect(cleaned, contains('Foodland'));
    expect(cleaned, isNot(contains('**')));
    expect(cleaned, isNot(contains('https://x.com')));
  });
}
