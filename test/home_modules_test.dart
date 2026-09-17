import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/home/home_modules.dart';

void main() {
  final defaults = HomeModules.defaultIds;

  test('default catalog starts with Shopping and ends with Games', () {
    expect(defaults.first, 'shopping');
    expect(defaults.last, 'games');
    expect(defaults, containsAll(['weather', 'polar', 'anchor']));
    expect(defaults.toSet().length, defaults.length);
    expect(HomeModules.catalog.length, defaults.length);
  });

  test('merge of null or empty yields the default order', () {
    expect(HomeModules.merge(null), defaults);
    expect(HomeModules.merge(const []), defaults);
  });

  test('merge keeps a full custom order', () {
    final saved = ['weather', ...defaults.where((id) => id != 'weather')];
    expect(HomeModules.merge(saved), saved);
    expect(saved.first, 'weather');
  });

  test('merge drops unknown ids', () {
    final saved = ['weather', 'not_a_module', 'shopping'];
    final merged = HomeModules.merge(saved);
    expect(merged.contains('not_a_module'), isFalse);
    expect(merged.first, 'weather');
    expect(merged, contains('shopping'));
    expect(merged.toSet(), defaults.toSet());
  });

  test('merge inserts a missing catalog id after its default predecessor', () {
    final withoutPolar = defaults.where((id) => id != 'polar').toList();
    expect(HomeModules.merge(withoutPolar), defaults);

    final weatherFirst = [
      'weather',
      ...defaults.where((id) => id != 'weather' && id != 'polar'),
    ];
    final merged = HomeModules.merge(weatherFirst);
    expect(merged.indexOf('polar'), merged.indexOf('weather') + 1);
    expect(merged.toSet(), defaults.toSet());
  });

  test('moveIdTo puts weather at the front', () {
    final moved = HomeModules.moveIdTo(defaults, 'weather', 0);
    expect(moved.first, 'weather');
    expect(moved[1], 'shopping');
    expect(moved.contains('weather'), isTrue);
    expect(moved.toSet(), defaults.toSet());
  });

  test('moveIdTo is a no-op on the same slot', () {
    expect(HomeModules.moveIdTo(defaults, 'shopping', 0), defaults);
    expect(HomeModules.moveIdTo(defaults, 'unknown', 0), defaults);
  });

  test('resolve maps a full custom id list to modules in that order', () {
    final full = [
      'weather',
      ...HomeModules.defaultIds.where((id) => id != 'weather'),
    ];
    final modules = HomeModules.resolve(full);
    expect(modules.map((m) => m.id).toList(), full);
  });

  test('resolve of a partial list still returns every catalog module', () {
    final modules = HomeModules.resolve(['weather', 'games']);
    expect(modules.length, HomeModules.catalog.length);
    expect(modules.map((m) => m.id).toSet(), HomeModules.defaultIds.toSet());
  });
}
