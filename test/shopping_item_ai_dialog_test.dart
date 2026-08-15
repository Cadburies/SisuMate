import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/shopping/shopping_item_ai_dialog.dart';

/// #337 — per-item sparkle is the offline guide only; live shops live on
/// the list-level port run.
void main() {
  testWidgets('offline guide, no competing AI buttons, can open port run',
      (tester) async {
    var planned = false;
    final item = ShoppingItem()
      ..name = 'Duty-free rum'
      ..quantity = 1
      ..origin = 'bar';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShoppingItemAiDialog(
          item: item,
          onPlanPortRun: () => planned = true,
        ),
      ),
    ));

    expect(find.textContaining('Offline shopping guide'), findsOneWidget);
    expect(find.textContaining('Duty-free rum'), findsWidgets);
    expect(find.text('Find nearest shop (online)'), findsNothing);
    expect(find.text('Improve with AI (online)'), findsNothing);
    expect(find.text('Plan port run for this list'), findsOneWidget);

    await tester.ensureVisible(find.text('Plan port run for this list'));
    await tester.tap(find.text('Plan port run for this list'));
    await tester.pump();
    expect(planned, isTrue);
  });
}
