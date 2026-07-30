import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/lan/lan_engine.dart';
import 'package:sisu_mate/services/lan/share_lan_service.dart';

// Covers F14's serialization + protocol wiring that doesn't need a live socket
// or mDNS, mirroring lan_reconnect_test.dart. The full connect-then-pull flow
// needs a real network and isn't exercised here.
void main() {
  group('SharePayload serialization', () {
    test('recipe payload round-trips through toJson/fromJson', () {
      final recipe = Recipe()
        ..supabaseId = 'r1'
        ..name = 'Dark & Stormy'
        ..recipeType = 'cocktail'
        ..glassware = 'Highball'
        ..instructions = 'Build over ice.'
        ..tastingLog = [
          TastingRecord()
            ..location = 'Cockpit'
            ..notes = 'Great at anchor'
            ..rating = 5
            ..tastedAt = DateTime.parse('2026-07-01T18:00:00.000'),
        ];
      final ingredients = [
        RecipeIngredient()
          ..name = 'Dark rum'
          ..quantity = 60
          ..unit = 'ml'
          ..sortOrder = 0,
        RecipeIngredient()
          ..name = 'Lime wedge'
          ..isGarnish = true
          ..sortOrder = 1,
      ];

      final decoded = SharePayload.fromJson(
        SharePayload.recipe(recipe, ingredients).toJson(),
      );

      expect(decoded.kind, ShareKind.recipe);
      expect(decoded.recipe!.name, 'Dark & Stormy');
      expect(decoded.recipe!.glassware, 'Highball');
      expect(decoded.recipe!.tastingLog.single.rating, 5);
      expect(decoded.ingredients.length, 2);
      expect(decoded.ingredients.first.quantity, 60);
      expect(decoded.ingredients.first.unit, 'ml');
      expect(decoded.ingredients.last.isGarnish, isTrue);
    });

    test('crew payload round-trips through toJson/fromJson', () {
      final crew = [
        CrewMember()
          ..name = 'Alex'
          ..role = 'Skipper'
          ..phone = '+358401234567'
          ..certifications = 'STCW',
        CrewMember()
          ..name = 'Sam'
          ..role = 'Crew',
      ];

      final decoded = SharePayload.fromJson(
        SharePayload.crew(crew).toJson(),
      );

      expect(decoded.kind, ShareKind.crew);
      expect(decoded.crew.length, 2);
      expect(decoded.crew.first.name, 'Alex');
      expect(decoded.crew.first.role, 'Skipper');
      expect(decoded.crew.first.certifications, 'STCW');
      expect(decoded.crew.last.name, 'Sam');
    });
  });

  group('ShareLanService', () {
    test('is not a host until hostShare is called', () {
      final service = ShareLanService(LanEngine());
      expect(service.isHost, isFalse);
    });

    test('incomingContent is a broadcast stream (multiple listeners allowed)',
        () {
      final service = ShareLanService(LanEngine());
      final a = service.incomingContent.listen((_) {});
      final b = service.incomingContent.listen((_) {});
      addTearDown(a.cancel);
      addTearDown(b.cancel);
      expect(service.incomingContent.isBroadcast, isTrue);
    });
  });
}
