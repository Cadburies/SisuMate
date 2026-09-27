import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/feature_map.dart';

/// #354: the Feature Map lint runs in the suite (errors fail it), and each
/// error rule is pinned by a fixture so the lint itself can't silently rot.
void main() {
  test('the real feature map lints clean', () {
    final r = lint(Directory(featureMapRoot));
    expect(r.errors, isEmpty, reason: r.errors.join('\n'));
  });

  group('lint rules', () {
    late Directory repo;
    late Directory root;

    String file(Map<String, String> overrides) {
      final f = {
        'title': 'T', 'desc': 'D', 'layer': 'ux', 'keywords': 'k', 'kind': 'screen', //
        'looks': '-', 'reach': 'text:Go', 'needs': '-', 'action': '-', 'expect': '-',
        'uses': '-', 'script': 'area', 'source': 'lib/x.dart (Widget)',
        ...overrides,
      };
      return featureFields.map((k) => '$k: ${f[k]}').join('\n');
    }

    void write(String id, String text) {
      File('${root.path}/$id.md')
        ..createSync(recursive: true)
        ..writeAsStringSync(text);
    }

    List<String> errors() => lint(root, repo: repo).errors;

    setUp(() {
      repo = Directory.systemTemp.createTempSync('fm_lint_');
      root = Directory('${repo.path}/map')..createSync();
      File('${repo.path}/lib/x.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('class Widget {}');
      File('${repo.path}/test/feature_map/area_test.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("testWidgets('home', (t) async {});");
      write('home', file({'reach': '-'}));
    });

    tearDown(() => repo.deleteSync(recursive: true));

    test('a valid map has no errors', () => expect(errors(), isEmpty));

    test('missing template key', () {
      write('home', 'title: T');
      expect(errors().single, contains('missing'));
    });

    test('keys out of order', () {
      final lines = file({'reach': '-'}).split('\n');
      write('home', [lines[1], lines[0], ...lines.skip(2)].join('\n'));
      expect(errors(), contains(contains('in order')));
    });

    test('unknown layer / kind / needs', () {
      write('home', file({'reach': '-', 'layer': 'magic', 'kind': 'blob', 'needs': 'tier=gold'}));
      expect(errors(), containsAll([contains('layer'), contains('kind'), contains('tier=gold')]));
    });

    test('malformed reach step', () {
      write('home', file({'reach': 'poke:Go > swipe:Row'}));
      expect(errors(), containsAll([contains('poke'), contains('swipe needs')]));
    });

    test('missing source file or symbol', () {
      write('home', file({'reach': '-', 'source': 'lib/x.dart (Nope); lib/gone.dart'}));
      expect(errors(), containsAll([contains('"Nope"'), contains('lib/gone.dart')]));
    });

    test('script area file or named test missing', () {
      write('home', file({'reach': '-', 'script': 'nowhere'}));
      write('home/a', file({'script': 'area'}));
      expect(errors(), containsAll([contains('nowhere_test.dart'), contains("test named 'home/a'")]));
    });

    test('tree folder without its node file', () {
      write('home/x/y', file({'script': '-'}));
      expect(errors(), contains(contains('home/x/: folder has no home/x.md')));
    });

    test('bad root and system layer ux', () {
      write('elsewhere/a', file({'script': '-'}));
      write('system/logic/a', file({'script': '-'}));
      expect(errors(), containsAll([contains('root must be'), contains('cannot be layer ux')]));
    });

    test('dangling uses is an error (#382)', () {
      write('home', file({'reach': '-', 'uses': 'system/db/nope'}));
      expect(errors(), contains(contains('system/db/nope')));
    });

    test('UI script: - is an error unless platform=device', () {
      write('home', file({'reach': '-', 'script': '-'}));
      expect(errors(), contains(contains('script: -')));
      write('home', file({'reach': '-', 'script': '-', 'needs': 'platform=device'}));
      expect(errors(), isEmpty);
    });

    test('audit reports screens and services no feature references', () {
      File('${repo.path}/lib/ui/x/orphan_screen.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('class OrphanScreen {}');
      File('${repo.path}/lib/services/orphan_service.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('class OrphanService {}');
      final r = audit(root, repo: repo);
      expect(r.unmappedScreens.single, contains('OrphanScreen'));
      expect(r.unmappedServices.single, 'lib/services/orphan_service.dart');
    });
  });

  test('touches derive from source + script + file; hotspots conflict', () {
    Feature f(String id, String source, String script, [String uses = '-']) =>
        Feature(id, {'source': source, 'script': script, 'uses': uses, 'layer': 'ux'});
    final features = [
      f('home/a', 'lib/ui/a.dart (A)', 'area', 'system/x'),
      f('home/b', 'lib/ui/b.dart (B)', 'other', 'system/x'),
      f('home/c', 'lib/ui/a.dart (C)', '-'),
      f('system/x', 'lib/core/di.dart', '-'),
    ];
    final t = touchesOf(features, 'home/a');
    expect(t.touches, containsAll(['lib/ui/a.dart', 'test/feature_map/area_test.dart']));
    expect(t.deps, {'lib/core/di.dart'});
    expect(overlapOf(features, 'home/a', 'home/c'), {'lib/ui/a.dart'});
    // Both depend on a hotspot: not parallel-safe even though neither edits it.
    expect(overlapOf(features, 'home/a', 'home/b'), {'lib/core/di.dart'});
  });

  test('the real map has no unmapped screens, routes or services', () {
    final r = audit(Directory(featureMapRoot));
    expect(r.unmappedScreens, isEmpty);
    expect(r.unmappedRouteWidgets, isEmpty);
    expect(r.unmappedServices, isEmpty);
  });

  test('path walks root to leaf through existing nodes', () {
    final features = [
      Feature('home', {}),
      Feature('home/shopping', {}),
      Feature('home/shopping/add_item', {}),
    ];
    expect(pathTo(features, 'home/shopping/add_item').map((f) => f.id),
        ['home', 'home/shopping', 'home/shopping/add_item']);
  });
}
