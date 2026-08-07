import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/components/ad_slots.dart';

void main() {
  group('pickNativeAdSlots', () {
    test('no ads for lists of 2 or fewer items', () {
      expect(pickNativeAdSlots(itemCount: 0), isEmpty);
      expect(pickNativeAdSlots(itemCount: 1), isEmpty);
      expect(pickNativeAdSlots(itemCount: 2), isEmpty);
    });

    test('never places an ad at index 0 or 1', () {
      for (var seed = 0; seed < 50; seed++) {
        final slots =
            pickNativeAdSlots(itemCount: 30, random: Random(seed));
        expect(slots.every((s) => s >= 2), isTrue,
            reason: 'seed $seed put an ad at ${slots.first}');
      }
    });

    test('at most 4 ads, all distinct, none adjacent', () {
      for (var seed = 0; seed < 100; seed++) {
        final slots =
            pickNativeAdSlots(itemCount: 40, random: Random(seed));
        expect(slots.length, lessThanOrEqualTo(4));
        expect(slots.toSet().length, slots.length,
            reason: 'duplicate slots at seed $seed');
        for (var i = 1; i < slots.length; i++) {
          expect(slots[i] - slots[i - 1], greaterThanOrEqualTo(2),
              reason: 'adjacent ads at seed $seed: $slots');
        }
      }
    });

    test('all slots are inside the beginning window', () {
      final slots = pickNativeAdSlots(itemCount: 200, random: Random(7));
      expect(slots.every((s) => s < 16), isTrue);
      expect(slots.length, 4);
    });

    test('window shrinks to the item count for short lists', () {
      final slots = pickNativeAdSlots(itemCount: 5, random: Random(3));
      expect(slots.every((s) => s >= 2 && s < 5), isTrue);
    });

    test('deterministic for the same seed', () {
      final a = pickNativeAdSlots(itemCount: 30, random: Random(42));
      final b = pickNativeAdSlots(itemCount: 30, random: Random(42));
      expect(a, b);
    });
  });

  group('NativeAdSlotCache', () {
    test('stable across calls with the same count, re-rolls on count change',
        () {
      final cache = NativeAdSlotCache();
      final a = cache(30);
      expect(cache(30), same(a),
          reason: 'rebuilds must not reshuffle ad positions');
      final b = cache(31);
      expect(b, isNot(same(a)), reason: 'count change re-rolls slots');
      expect(cache(31), same(b));
    });

    test('#311 forList with showAds:false returns no slots (Pro path)', () {
      final cache = NativeAdSlotCache();
      expect(cache.forList(40, showAds: false), isEmpty);
      // Enabling ads still uses the memoized picker for that count.
      final free = cache.forList(40, showAds: true);
      expect(free, isNotEmpty);
      expect(free.length, lessThanOrEqualTo(4));
      expect(cache.forList(40, showAds: true), same(free));
      expect(cache.forList(40, showAds: false), isEmpty);
    });
  });

  group('slot mapping', () {
    test('every content index appears exactly once, in order', () {
      const itemCount = 12;
      final slots = [2, 5, 9];
      final seen = <int>[];
      for (var i = 0; i < itemCount + slots.length; i++) {
        if (isNativeAdSlot(i, slots)) continue;
        seen.add(nativeAdContentIndex(i, slots));
      }
      expect(seen, List.generate(itemCount, (i) => i));
    });

    test('mapping around a single ad', () {
      final slots = [3];
      expect(nativeAdContentIndex(0, slots), 0);
      expect(nativeAdContentIndex(1, slots), 1);
      expect(nativeAdContentIndex(2, slots), 2);
      // 3 is the ad slot itself.
      expect(isNativeAdSlot(3, slots), isTrue);
      expect(nativeAdContentIndex(4, slots), 3);
      expect(nativeAdContentIndex(5, slots), 4);
    });
  });
}
