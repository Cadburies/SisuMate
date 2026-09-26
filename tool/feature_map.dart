// Feature Map CLI + lint (#354). Format: .ai_context/feature_map/FORMAT.md.
//
//   dart run tool/feature_map.dart lint            # errors fail (exit 1), warnings print
//   dart run tool/feature_map.dart find <keyword>  # ids whose fields match
//   dart run tool/feature_map.dart path <id>       # root → id walk (reach, needs, script)
//   dart run tool/feature_map.dart script <id>     # how scripts/fm.sh runs it (one line)
//   dart run tool/feature_map.dart touches <id>... # derived Touches list for an issue
//   dart run tool/feature_map.dart overlap <id> <id>  # can two features be worked in parallel?
//
// Pure Dart (dart:io only) so it runs without Flutter; also imported by tests
// and tool/feature_map_wiki.dart.
import 'dart:io';

const featureMapRoot = '.ai_context/feature_map';

const featureFields = [
  'title', 'desc', 'layer', 'keywords', 'kind', 'looks', 'reach', //
  'needs', 'action', 'expect', 'uses', 'script', 'source',
];

const layers = {
  'ux', 'db', 'sync', 'network', 'auth', 'pro', 'ads', 'ai', 'platform', //
  'lan', 'logic', 'errors', 'ops',
};

const kinds = {
  'screen', 'dialog', 'sheet', 'drawer', 'banner', 'card', 'button', 'fab', //
  'tile', 'chip', 'swipe', 'menu', 'toggle', 'field', 'longpress', 'service', 'job',
  'repo', 'script', 'test',
};

const needValues = {
  'onboarding': {'seen', 'unseen'},
  'tier': {'free', 'pro', 'free_limited'},
  'boat': {'none', 'active', 'multiple'},
  'auth': {'none', 'owner', 'crew', 'developer'},
  'network': {'online', 'offline'},
  'platform': {'host', 'device', 'android', 'ios'},
  'build': {'debug'},
};

const reachVerbs = {'text', 'tip', 'label', 'long', 'swipe', 'type', 'wait'};

/// Root-level docs that are not feature files.
const _nonFeatureFiles = {'FORMAT.md', 'DESIGN.md', 'INDEX.md', 'README.md'};

/// Roots whose folders must each have a same-named feature file (tree nodes).
/// `system/` and `shared/` folders are plain groupings.
const _treeRoots = {'home', 'launch'};

class Feature {
  final String id;
  final Map<String, String> fields;
  final List<String> keyOrder;
  Feature(this.id, this.fields, [this.keyOrder = const []]);

  /// Raw field value; `-` when absent.
  String raw(String key) => fields[key] ?? '-';
  String get root => id.split('/').first;
  bool get isUx => raw('layer') == 'ux';

  /// `k=v` pairs from `needs` (notes in parentheses dropped).
  Map<String, String> get needs {
    final out = <String, String>{};
    final n = raw('needs');
    if (n == '-') return out;
    for (final token in n.split(' · ')) {
      final m = RegExp(r'^(\w+)=(\w+)').firstMatch(token.trim());
      if (m != null) out[m[1]!] = m[2]!;
    }
    return out;
  }

  /// UI `reach` split into steps; empty for `-` or non-UI features.
  List<String> get reachSteps {
    final r = raw('reach');
    if (!isUx || r == '-') return const [];
    return r.split(' > ').map((s) => s.trim()).toList();
  }
}

class FeatureMapError implements Exception {
  final String message;
  FeatureMapError(this.message);
  @override
  String toString() => message;
}

/// Parses one 13-line `key: value` feature file. Throws on missing keys.
Feature parseFeature(String id, String text) {
  final fields = <String, String>{};
  final order = <String>[];
  for (final line in text.split('\n')) {
    if (line.trim().isEmpty) continue;
    final i = line.indexOf(': ');
    if (i <= 0) {
      throw FeatureMapError('$id: line is not "key: value": "$line"');
    }
    final key = line.substring(0, i).trim();
    order.add(key);
    fields[key] = line.substring(i + 2).trim();
  }
  final missing = featureFields.where((k) => !fields.containsKey(k)).toList();
  if (missing.isNotEmpty) {
    throw FeatureMapError('$id: missing ${missing.join(', ')}');
  }
  return Feature(id, fields, order);
}

String _rel(Directory root, FileSystemEntity e) =>
    e.path.substring(root.path.length + 1).replaceAll(r'\', '/');

List<Feature> loadFeatures(Directory root) {
  final features = <Feature>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.md')) continue;
    final rel = _rel(root, entity);
    if (!rel.contains('/') && _nonFeatureFiles.contains(rel)) continue;
    features.add(parseFeature(rel.substring(0, rel.length - 3), entity.readAsStringSync()));
  }
  features.sort((a, b) => a.id.compareTo(b.id));
  return features;
}

class LintResult {
  final List<String> errors = [];
  final List<String> warnings = [];
  bool get ok => errors.isEmpty;
}

/// Checks one reach step's grammar; returns an error message or null.
String? checkReachStep(String step) {
  if (step == 'back') return null;
  final colon = step.indexOf(':');
  if (colon <= 0) return 'reach step "$step" is not verb:arg or back';
  final verb = step.substring(0, colon);
  final arg = step.substring(colon + 1);
  if (!reachVerbs.contains(verb)) return 'unknown reach verb "$verb"';
  if (arg.trim().isEmpty) return 'reach step "$step" has no target';
  if (verb == 'swipe' && !arg.contains(':')) return 'swipe needs <row>:<action>';
  if (verb == 'type' && !arg.contains('=')) return 'type needs <field>=<value>';
  return null;
}

/// Parses `source` into (path, symbols) entries: `a.dart (X, Y.z); b.dart`.
List<(String, List<String>)> parseSource(String source) {
  if (source == '-') return const [];
  final out = <(String, List<String>)>[];
  for (final part in source.split(';')) {
    final m = RegExp(r'^\s*(\S+)\s*(?:\((.*)\))?\s*$').firstMatch(part);
    if (m == null) continue;
    final syms = (m[2] ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    out.add((m[1]!, syms));
  }
  return out;
}

/// Where a `script:` value resolves: a test file path, and whether that file
/// must hold a test named by the feature id.
({String path, bool named})? resolveScript(Feature f) {
  final s = f.raw('script');
  if (s == '-') return null;
  if (s.contains('/')) return (path: s, named: false);
  return (path: 'test/feature_map/${s}_test.dart', named: true);
}

String _readTree(String path) {
  final dir = Directory(path);
  if (dir.existsSync()) {
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.sh'))
        .map((f) => f.readAsStringSync())
        .join('\n');
  }
  return File(path).readAsStringSync();
}

/// Lints every feature under [root]; [repo] resolves `source`/`script` paths.
LintResult lint(Directory root, {Directory? repo}) {
  final result = LintResult();
  final base = repo?.path ?? '.';
  List<Feature> features;
  try {
    features = loadFeatures(root);
  } on FeatureMapError catch (e) {
    result.errors.add(e.message);
    return result;
  }
  final ids = {for (final f in features) f.id};

  for (final f in features) {
    final id = f.id;
    if (f.keyOrder.length != featureFields.length ||
        !List.generate(featureFields.length, (i) => f.keyOrder[i] == featureFields[i])
            .every((x) => x)) {
      result.errors.add('$id: keys must be exactly the 13 template keys in order');
    }
    if (!{'home', 'launch', 'shared', 'system'}.contains(f.root)) {
      result.errors.add('$id: root must be home/, launch/, shared/ or system/');
    }
    if (!layers.contains(f.raw('layer'))) result.errors.add('$id: unknown layer "${f.raw('layer')}"');
    if (!kinds.contains(f.raw('kind'))) result.errors.add('$id: unknown kind "${f.raw('kind')}"');
    if (f.root == 'system' && f.isUx) result.errors.add('$id: system/ features cannot be layer ux');

    final needs = f.raw('needs');
    if (needs != '-') {
      for (final token in needs.split(' · ')) {
        final m = RegExp(r'^(\w+)=(\w+)(\s*\(.*\))?$').firstMatch(token.trim());
        if (m == null) {
          result.errors.add('$id: needs token "$token" is not k=v (note)');
          continue;
        }
        final allowed = needValues[m[1]];
        if (allowed == null || !allowed.contains(m[2])) {
          result.errors.add('$id: unknown needs "${m[1]}=${m[2]}"');
        }
      }
    }

    if (f.isUx && f.raw('reach') != '-') {
      for (final step in f.reachSteps) {
        final e = checkReachStep(step);
        if (e != null) result.errors.add('$id: $e');
      }
    }

    for (final (path, syms) in parseSource(f.raw('source'))) {
      final full = '$base/$path';
      if (!File(full).existsSync() && !Directory(full).existsSync()) {
        result.errors.add('$id: source "$path" not found');
        continue;
      }
      final text = _readTree(full);
      for (final sym in syms) {
        for (final part in sym.split('.')) {
          if (!RegExp('\\b${RegExp.escape(part)}\\b').hasMatch(text)) {
            result.errors.add('$id: symbol "$part" not found in $path');
          }
        }
      }
    }

    final script = resolveScript(f);
    if (script == null) {
      if (f.isUx) result.warnings.add('$id: UI feature has script: -');
    } else {
      final file = File('$base/${script.path}');
      if (!file.existsSync()) {
        result.errors.add('$id: script file ${script.path} not found');
      } else if (script.named) {
        final text = file.readAsStringSync();
        if (!text.contains("'$id'") && !text.contains("'$id [")) {
          result.errors.add("$id: ${script.path} has no test named '$id'");
        }
      }
    }

    final uses = f.raw('uses');
    if (uses != '-') {
      for (final u in uses.split(',').map((s) => s.trim())) {
        if (!ids.contains(u)) result.warnings.add('$id: uses "$u" does not exist yet');
      }
    }
  }

  // Tree folders under home/ and launch/ need their same-named node file.
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! Directory) continue;
    final rel = _rel(root, entity);
    if (!_treeRoots.contains(rel.split('/').first)) continue;
    if (!ids.contains(rel)) result.errors.add('$rel/: folder has no $rel.md');
  }
  return result;
}

/// Single-owner hotspots from CLAUDE.md §Parallel agents: never touched by
/// two claimed issues at once.
const hotspots = {
  'lib/core/di.dart', 'lib/data/drift/app_database.dart', 'lib/core/app_router.dart',
  'lib/models/models.dart', 'lib/core/units.dart', 'lib/ui/games/lobby/lobby_screen.dart',
  'lib/services/suggestion_engine.dart', 'lib/services/mixologist_service.dart',
  'scripts/run_full_suite.sh', 'scripts/scan_release_secrets.sh',
};

/// Files an issue on [id] may change (derived, never hand-maintained): the
/// feature file, its `source` files and its `script` file. `uses` targets'
/// sources are returned separately as read-mostly dependencies.
({Set<String> touches, Set<String> deps}) touchesOf(List<Feature> features, String id) {
  final byId = {for (final f in features) f.id: f};
  final f = byId[id];
  if (f == null) throw FeatureMapError('no feature "$id"');
  final touches = <String>{
    '$featureMapRoot/$id.md',
    for (final (path, _) in parseSource(f.raw('source'))) path,
    if (resolveScript(f) case final s?) s.path,
  };
  final deps = <String>{};
  final uses = f.raw('uses');
  if (uses != '-') {
    for (final u in uses.split(',').map((s) => s.trim())) {
      for (final (path, _) in parseSource(byId[u]?.raw('source') ?? '-')) {
        if (!touches.contains(path)) deps.add(path);
      }
    }
  }
  return (touches: touches, deps: deps);
}

/// Shared files between two features' touches (hotspots always conflict,
/// even as a dependency).
Set<String> overlapOf(List<Feature> features, String a, String b) {
  final ta = touchesOf(features, a), tb = touchesOf(features, b);
  return {
    ...ta.touches.intersection(tb.touches),
    ...{...ta.touches, ...ta.deps}.intersection({...tb.touches, ...tb.deps}).intersection(hotspots),
  };
}

/// Ancestors (that exist) from root to [id], inclusive.
List<Feature> pathTo(List<Feature> features, String id) {
  final byId = {for (final f in features) f.id: f};
  if (!byId.containsKey(id)) throw FeatureMapError('no feature "$id"');
  final segs = id.split('/');
  return [
    for (var i = 1; i <= segs.length; i++) ?byId[segs.sublist(0, i).join('/')],
  ];
}

List<Feature> find(List<Feature> features, String keyword) {
  final k = keyword.toLowerCase();
  return features
      .where((f) =>
          f.id.toLowerCase().contains(k) ||
          ['title', 'desc', 'keywords', 'looks', 'action']
              .any((key) => f.raw(key).toLowerCase().contains(k)))
      .toList();
}

void main(List<String> args) {
  final root = Directory(featureMapRoot);
  final cmd = args.isEmpty ? 'lint' : args.first;
  try {
    switch (cmd) {
      case 'lint':
        final r = lint(root);
        for (final w in r.warnings) {
          stdout.writeln('warning: $w');
        }
        for (final e in r.errors) {
          stderr.writeln('error: $e');
        }
        stdout.writeln('feature map: ${r.errors.length} errors, ${r.warnings.length} warnings');
        exit(r.ok ? 0 : 1);
      case 'find':
        for (final f in find(loadFeatures(root), args.skip(1).join(' '))) {
          stdout.writeln('${f.id}  —  ${f.raw('title')}');
        }
      case 'path':
        for (final f in pathTo(loadFeatures(root), args[1])) {
          stdout.writeln('${f.id}: ${f.raw('title')}\n  reach: ${f.raw('reach')}\n'
              '  needs: ${f.raw('needs')}\n  script: ${f.raw('script')}');
        }
      case 'script':
        final f = pathTo(loadFeatures(root), args[1]).last;
        final s = resolveScript(f);
        stdout.writeln(s == null ? '-' : '${s.path} ${s.named ? 'named' : 'file'}');
      case 'touches':
        final features = loadFeatures(root);
        final touches = <String>{}, deps = <String>{};
        for (final id in args.skip(1)) {
          final t = touchesOf(features, id);
          touches.addAll(t.touches);
          deps.addAll(t.deps);
        }
        for (final p in touches.toList()..sort()) {
          stdout.writeln('- `$p`${hotspots.contains(p) ? ' (HOTSPOT: single owner)' : ''}');
        }
        for (final p in deps.difference(touches).toList()..sort()) {
          stdout.writeln('- `$p` (dependency, read-mostly${hotspots.contains(p) ? ', HOTSPOT' : ''})');
        }
      case 'overlap':
        final shared = overlapOf(loadFeatures(root), args[1], args[2]);
        stdout.writeln(shared.isEmpty ? 'parallel-safe' : 'CONFLICT: ${shared.join(', ')}');
        exit(shared.isEmpty ? 0 : 2);
      default:
        stderr.writeln('usage: feature_map.dart lint | find <kw> | path <id> | script <id> | '
            'touches <id>... | overlap <a> <b>');
        exit(64);
    }
  } on FeatureMapError catch (e) {
    stderr.writeln('feature map: $e');
    exit(1);
  }
}
