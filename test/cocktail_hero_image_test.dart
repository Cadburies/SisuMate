import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/cocktails/cocktail_art.dart';
import 'package:sisu_mate/ui/components/smart_image.dart';

/// #350: iPad full-bleed × 200 cover cropped 3:2 cocktail art into a strip.
void main() {
  testWidgets('detail hero on a tablet-width canvas stays 3:2, not a short strip',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1024,
            height: 800,
            child: CocktailArt(
              assetName: 'cocktails/_default_rocks.jpg',
              detail: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final size = tester.getSize(find.byType(SmartImage));
    expect(size.width, CocktailArt.detailMaxWidth);
    expect(size.height, CocktailArt.detailMaxWidth / CocktailArt.aspectRatio);
    expect(size.width / size.height, closeTo(CocktailArt.aspectRatio, 0.01));
    expect(size.width / size.height, lessThan(2.5));
  });

  testWidgets('card art fills available width at 3:2', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: CocktailArt(
              assetName: 'cocktails/_default_tiki.jpg',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final size = tester.getSize(find.byType(SmartImage));
    expect(size.width, 240);
    expect(size.height, closeTo(240 / CocktailArt.aspectRatio, 0.5));
  });
}
