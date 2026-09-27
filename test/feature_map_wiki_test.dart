import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/feature_map_wiki.dart';

/// #394: the public wiki is generated from `.ai_context/feature_map/`. These
/// guard the translation and, via the last test, that every real feature file
/// stays publishable (no leaked internals, no page-name clashes).
void main() {
  Feature feature(String id, Map<String, String> overrides) {
    final base = {for (final k in featureFields) k: '-'}
      ..addAll({'title': 'T', 'desc': 'D', 'layer': 'ux'})
      ..addAll(overrides);
    return parseFeature(id, base.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
  }

  test('parseFeature rejects a file missing template keys', () {
    expect(() => parseFeature('x', 'title: A\ndesc: B'), throwsA(isA<FeatureMapError>()));
  });

  test('only user features are published', () {
    expect(isPublished(feature('home/a', {})), isTrue);
    expect(isPublished(feature('system/logic/a', {'layer': 'logic'})), isFalse);
    expect(isPublished(feature('home/a', {'needs': 'auth=developer'})), isFalse);
    expect(isPublished(feature('home/a', {'needs': 'build=debug'})), isFalse);
  });

  test('reach steps become plain numbered steps', () {
    final f = feature('home/shopping/add_item', {
      'reach': 'text:Shopping > tip:Add item > swipe:Impeller:Complete > type:Item Name=Rope > back',
    });
    expect(reachSteps(f), [
      'Open Sisu Mate on the Home screen.',
      'Tap **Shopping**.',
      'Tap the **Add item** button.',
      'Swipe **Impeller** and tap **Complete**.',
      'Enter **Rope** in **Item Name**.',
      'Go back.',
    ]);
    expect(() => reachSteps(feature('home/a', {'reach': 'poke:X'})), throwsA(isA<FeatureMapError>()));
  });

  test('needs become plain requirements; test-only keys dropped', () {
    final f = feature('home/a', {'needs': 'onboarding=seen · tier=pro (Free shows an upgrade prompt) · platform=device'});
    expect(needsLines(f), ['Sisu Mate Pro. Free shows an upgrade prompt']);
  });

  test('leak check refuses code-like published text', () {
    expect(() => leakCheck(feature('home/a', {'action': 'Calls _showAddItemDialog'})), throwsA(isA<FeatureMapError>()));
    expect(() => leakCheck(feature('home/a', {'desc': 'See lib/ui/x.dart'})), throwsA(isA<FeatureMapError>()));
    expect(() => leakCheck(feature('home/a', {'source': 'lib/ui/x.dart (_private)'})), returnsNormally);
  });

  test('page names use ancestor titles and never leak source/script', () {
    final shopping = feature('home/shopping', {'title': 'Shopping & Spares'});
    final add = feature('home/shopping/add_item', {
      'title': 'Add shopping item',
      'needs': 'tier=pro',
      'source': 'lib/ui/shopping/shopping_screen.dart',
      'script': 'shopping',
    });
    final pages = renderWiki([shopping, add]);
    expect(pages.keys, containsAll(['Shopping & Spares - Add shopping item.md', 'Home.md', '_Sidebar.md']));
    final page = pages['Shopping & Spares - Add shopping item.md']!;
    expect(page, contains('[[Shopping & Spares]]'));
    expect(page, contains('**Pro feature**'));
    expect(page, isNot(contains('shopping_screen')));
    expect(pages['Shopping & Spares.md'], contains('[[Shopping & Spares - Add shopping item]]'));
  });

  test('angle brackets are escaped so the wiki does not strip them as HTML', () {
    final f = feature('home/a', {'expect': 'Shows "<name> added"'});
    expect(renderWiki([f]).values.join(), contains('&lt;name&gt; added'));
  });

  test('the real feature map renders cleanly', () {
    final pages = renderWiki(loadFeatures(Directory('.ai_context/feature_map')));
    expect(pages, contains('Home.md'));
  });

  test('#382 manual renders a published subtree in plain language', () {
    final text = renderManual(loadFeatures(Directory('.ai_context/feature_map')), 'home/shopping');
    expect(text, startsWith('# Shopping & Spares — user guide'));
    expect(text, contains('Tap the **Add item** button.'));
    expect(text, isNot(contains('lib/')));
  });
}
