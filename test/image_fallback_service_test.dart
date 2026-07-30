import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/image_fallback_service.dart';

void main() {
  group('ImageFallbackService.getFallbackAsset', () {
    test('returns the generic fallback when itemName or groupName is null', () {
      expect(ImageFallbackService.getFallbackAsset(null, 'Engine'), 'NoPicture.jpg');
      expect(ImageFallbackService.getFallbackAsset('Oil filter', null), 'NoPicture.jpg');
    });

    test('matches an engine-related group case-insensitively', () {
      expect(
        ImageFallbackService.getFallbackAsset('Oil filter', 'Engine Checks'),
        'lists/50HourEngineService/NoPicture.jpg',
      );
      expect(
        ImageFallbackService.getFallbackAsset('Oil filter', 'ENGINE hours'),
        'lists/50HourEngineService/NoPicture.jpg',
      );
    });

    test('matches a safety briefing group', () {
      expect(
        ImageFallbackService.getFallbackAsset('Life jackets', 'Safety Briefing'),
        'lists/DayTripSafetyBriefing/NoPicture.jpg',
      );
    });

    test('falls back to the generic image for an unrecognized group', () {
      expect(
        ImageFallbackService.getFallbackAsset('Item', 'Miscellaneous'),
        'NoPicture.jpg',
      );
    });
  });

  group('ImageFallbackService.isValidFallback', () {
    test('accepts every asset returned by getAllFallbackImages', () {
      for (final asset in ImageFallbackService.getAllFallbackImages()) {
        expect(ImageFallbackService.isValidFallback(asset), isTrue);
      }
    });

    test('rejects an arbitrary asset path', () {
      expect(ImageFallbackService.isValidFallback('lists/NotReal/NoPicture.jpg'), isFalse);
    });
  });
}
