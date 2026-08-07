import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/import_service.dart';
import 'package:sisu_mate/services/messy_import_local_parse.dart';

void main() {
  test('parses shopping CSV with header', () {
    const csv = 'name,quantity,unit,category\n'
        'Fenders,4,pcs,Deck\n'
        'Engine oil,2,L,Engine\n';
    final json = MessyImportLocalParse.tryParseEnvelope(
      csv,
      kind: ImportService.kindShopping,
    );
    expect(json, isNotNull);
    final batch = ImportService.parse(json!);
    expect(batch.kind, ImportService.kindShopping);
    expect(batch.count, 2);
    expect(batch.shoppingItems.first.item.name, 'Fenders');
  });

  test('parses one item per line for checklist', () {
    const text = '- Check bilge pump\n- Test nav lights\n* Secure dinghy\n';
    final json = MessyImportLocalParse.tryParseEnvelope(
      text,
      kind: ImportService.kindChecklist,
    );
    expect(json, isNotNull);
    final batch = ImportService.parse(json!);
    expect(batch.count, 3);
  });

  test('returns null for freeform prose paragraphs', () {
    const prose =
        'Yesterday we had a long day sailing up the coast with friends and '
        'the weather was complicated so I am not sure what we need to buy.';
    expect(
      MessyImportLocalParse.tryParseEnvelope(
        prose,
        kind: ImportService.kindShopping,
      ),
      isNull,
    );
  });
}
