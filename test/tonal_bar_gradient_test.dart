import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/colors.dart';
import 'package:sisu_mate/ui/components/sisu_tile_card.dart';

/// #342 — same-hue bar: darker ends, token colour in the middle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tonalBarGradient centre is the token; ends are darker same hue', () {
    const token = SisuColors.stateStockedBg;
    final g = SisuColors.tonalBarGradient(token);
    expect(g.colors, hasLength(3));
    expect(g.colors[1], token);
    expect(g.colors[0], g.colors[2]);
    final centre = HSLColor.fromColor(token);
    final edge = HSLColor.fromColor(g.colors[0]);
    expect(edge.lightness, lessThan(centre.lightness));
    expect(edge.hue, closeTo(centre.hue, 8));
  });

  testWidgets('SisuTileCard paints a gradient Ink, not a flat Card color',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SisuTileCard(
            color: SisuColors.stateShoppingBg,
            child: SizedBox(height: 48, width: 200, child: Text('row')),
          ),
        ),
      ),
    );
    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, Colors.transparent);
    expect(find.byType(Ink), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
