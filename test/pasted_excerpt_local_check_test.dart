import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/pasted_excerpt_local_check.dart';

void main() {
  group('PastedExcerptLocalCheck.warranty', () {
    test('a float switch inside a stated electrical term looks in scope', () {
      final text = PastedExcerptLocalCheck.warranty(
        situation: 'Bilge pump float switch stopped cycling after 3 months',
        excerpt:
            'Electrical components are warranted for 12 months from purchase.',
      );

      expect(text, contains('not a warranty determination'));
      expect(text, contains('possibly in scope of the pasted sentence'));
      expect(text, contains('inside the stated window'));
      expect(text, contains('float / switch'));
      expect(text, contains('warranted'));
    });

    test('a worn impeller lines up with a wear exclusion', () {
      final text = PastedExcerptLocalCheck.warranty(
        situation: 'Impeller worn out after 400 hours',
        excerpt: 'Wear and tear and consumable items are not covered.',
      );

      expect(text, contains('lines up with an exclusion in the excerpt'));
      expect(text, isNot(contains('possibly in scope')));
    });

    test('"not covered" is not read as coverage', () {
      final text = PastedExcerptLocalCheck.warranty(
        situation: 'The float switch failed',
        excerpt: 'Electrical items are not covered.',
      );

      expect(text, contains('lines up with an exclusion in the excerpt'));
      expect(text, isNot(contains('possibly in scope')));
    });

    test('a failure past the stated term is not called in scope', () {
      final text = PastedExcerptLocalCheck.warranty(
        situation: 'Electrical switch failed after 18 months',
        excerpt: 'Electrical components are warranted for 12 months.',
      );

      expect(text, contains('past the stated window'));
      expect(text, isNot(contains('possibly in scope')));
    });

    test('an unrelated excerpt says it cannot tell', () {
      final text = PastedExcerptLocalCheck.warranty(
        situation: 'Engine would not start',
        excerpt: 'See the dealer for details.',
      );

      expect(text, contains('does not say whether this is covered'));
      expect(text, contains('manufacturer or dealer'));
    });
  });

  group('PastedExcerptLocalCheck.insurance', () {
    test('storm damage to a rail names the pasted limit', () {
      final text = PastedExcerptLocalCheck.insurance(
        situation: 'Boom broke loose in a storm and cracked the rail',
        excerpt: 'Storm damage to fittings is covered up to \$5,000.',
      );

      expect(text, contains('not an insurance claim determination'));
      expect(text, contains('possibly in scope of the pasted sentence'));
      expect(text, contains('Limit named in the excerpt: \$5,000'));
      expect(text, contains('storm'));
    });

    test('a slow leak lines up with gradual deterioration', () {
      final text = PastedExcerptLocalCheck.insurance(
        situation: 'Slow leak over two years',
        excerpt: 'Gradual deterioration and wear and tear are excluded.',
      );

      expect(text, contains('lines up with an exclusion in the excerpt'));
      expect(text, isNot(contains('possibly in scope')));
      expect(text, contains('insurer or broker'));
    });
  });
}
