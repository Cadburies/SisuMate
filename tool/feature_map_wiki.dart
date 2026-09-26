// Renders the user-facing GitHub wiki from `.ai_context/feature_map/` (#394).
//
// The feature map is the single source; the wiki is generated output and is
// never edited by hand. Only user features are published (`layer: ux`, not
// developer/debug-only); `source`, `script` and `uses` never leave the repo.
//
// Usage: dart run tool/feature_map_wiki.dart <out-dir> [<feature-map-root>]
// Publishing (clone, sync, push) lives in scripts/publish_wiki.sh.
import 'dart:io';

const featureFields = [
  'title', 'desc', 'layer', 'keywords', 'kind', 'looks', 'reach', //
  'needs', 'action', 'expect', 'uses', 'script', 'source',
];

/// Root-level docs in the feature map that are not feature files.
const _nonFeatureFiles = {'FORMAT.md', 'DESIGN.md', 'INDEX.md', 'README.md'};

/// Fields that reach the public wiki — checked for leaked internals.
const _publishedFields = [
  'title', 'desc', 'keywords', 'looks', 'reach', 'needs', 'action', 'expect',
];

final _leakPattern = RegExp(r'lib/|\.dart\b|AppRoutes|\w\(\)|\b_[a-z]\w*[A-Z]');

class Feature {
  final String id;
  final Map<String, String> fields;
  Feature(this.id, this.fields);

  /// Field value with `<`/`>` escaped: GitHub wiki strips them as HTML tags.
  String operator [](String key) =>
      (fields[key] ?? '-').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  String get root => id.split('/').first;
}

class FeatureMapError implements Exception {
  final String message;
  FeatureMapError(this.message);
  @override
  String toString() => message;
}

/// Parses one 13-line `key: value` feature file.
Feature parseFeature(String id, String text) {
  final fields = <String, String>{};
  for (final line in text.split('\n')) {
    final i = line.indexOf(': ');
    if (i <= 0) continue;
    fields[line.substring(0, i).trim()] = line.substring(i + 2).trim();
  }
  final missing = featureFields.where((k) => !fields.containsKey(k)).toList();
  if (missing.isNotEmpty) {
    throw FeatureMapError('$id: missing ${missing.join(', ')}');
  }
  return Feature(id, fields);
}

List<Feature> loadFeatures(Directory root) {
  final features = <Feature>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.md')) continue;
    final rel = entity.path.substring(root.path.length + 1);
    if (!rel.contains('/') && _nonFeatureFiles.contains(rel)) continue;
    final id = rel.substring(0, rel.length - 3);
    features.add(parseFeature(id, entity.readAsStringSync()));
  }
  features.sort((a, b) => a.id.compareTo(b.id));
  return features;
}

bool isPublished(Feature f) =>
    f['layer'] == 'ux' &&
    f.root != 'system' &&
    !f['needs'].contains('auth=developer') &&
    !f['needs'].contains('build=debug');

/// Throws if a published field carries code-like text (paths, symbols, calls).
void leakCheck(Feature f) {
  for (final key in _publishedFields) {
    final m = _leakPattern.firstMatch(f.fields[key] ?? '-');
    if (m != null) {
      throw FeatureMapError(
          '${f.id}: "$key" looks internal ("${m[0]}"); published fields must be user language');
    }
  }
}

String _humanize(String segment) {
  final s = segment.replaceAll('_', ' ');
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

String _sanitize(String name) =>
    name.replaceAll(RegExp(r'[\\/:*?"<>|#\[\]]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

const _rootLabels = {'launch': 'First launch', 'shared': 'Everywhere'};

/// Wiki page name: ancestor titles (skipping `home`) + this feature's title.
String pageName(Feature f, Map<String, Feature> byId) {
  if (f.id == 'home') return 'Home screen';
  final segs = f.id.split('/');
  final parts = <String>[];
  for (var i = 0; i < segs.length - 1; i++) {
    if (i == 0 && segs[0] == 'home') continue;
    final ancestor = byId[segs.sublist(0, i + 1).join('/')];
    parts.add(ancestor?['title'] ??
        (i == 0 ? (_rootLabels[segs[0]] ?? _humanize(segs[0])) : _humanize(segs[i])));
  }
  parts.add(f['title']);
  return _sanitize(parts.join(' - '));
}

/// `text:Shopping > tip:Add item` → plain numbered steps.
List<String> reachSteps(Feature f) {
  final steps = <String>[
    f.root == 'launch'
        ? 'Open Sisu Mate for the first time.'
        : 'Open Sisu Mate on the Home screen.',
  ];
  final reach = f.fields['reach'] ?? '-';
  if (reach == '-' || f.id == 'home') return steps;
  for (final raw in reach.split(' > ')) {
    final step = raw.trim();
    final colon = step.indexOf(':');
    final verb = colon < 0 ? step : step.substring(0, colon);
    final arg = colon < 0 ? '' : step.substring(colon + 1);
    steps.add(switch (verb) {
      'text' || 'label' => 'Tap **$arg**.',
      'tip' => 'Tap the **$arg** button.',
      'long' => 'Press and hold **$arg**.',
      'swipe' => () {
          final i = arg.lastIndexOf(':');
          return 'Swipe **${arg.substring(0, i)}** and tap **${arg.substring(i + 1)}**.';
        }(),
      'type' => () {
          final i = arg.indexOf('=');
          return 'Enter **${arg.substring(i + 1)}** in **${arg.substring(0, i)}**.';
        }(),
      'wait' => 'Wait for **$arg** to appear.',
      'back' => 'Go back.',
      _ => throw FeatureMapError('${f.id}: unknown reach step "$step"'),
    });
  }
  return steps;
}

const _needPhrases = {
  'tier=pro': 'Sisu Mate Pro',
  'tier=free': 'Free version',
  'tier=free_limited': 'Free version (limited edits)',
  'boat=active': 'An active boat',
  'boat=multiple': 'More than one boat',
  'auth=owner': 'Signed in as the boat owner',
  'auth=crew': 'Joined a boat as crew',
  'network=online': 'An internet connection',
  'network=offline': 'Works offline',
};

/// `needs` → plain requirement lines. Test-only keys (onboarding, platform) are dropped.
List<String> needsLines(Feature f) {
  final needs = f['needs'];
  if (needs == '-') return const [];
  final lines = <String>[];
  for (final token in needs.split(' · ')) {
    final m = RegExp(r'^(\w+=\w+)\s*(?:\((.*)\))?$').firstMatch(token.trim());
    if (m == null) continue;
    final phrase = _needPhrases[m[1]];
    if (phrase == null) continue;
    lines.add(m[2] == null ? phrase : '$phrase. ${m[2]}');
  }
  return lines;
}

String renderPage(Feature f, Map<String, Feature> byId, Map<String, String> names) {
  final b = StringBuffer();
  final crumbs = <String>['[[Home]]'];
  final segs = f.id.split('/');
  for (var i = 0; i < segs.length - 1; i++) {
    final name = names[segs.sublist(0, i + 1).join('/')];
    if (name != null) crumbs.add('[[$name]]');
  }
  b.writeln('${crumbs.join(' › ')} › **${f['title']}**\n');
  if (f['needs'].contains('tier=pro')) b.writeln('> **Pro feature**\n');
  b.writeln('${f['desc']}\n');
  if (f['looks'] != '-') b.writeln('**Where:** ${f['looks']}\n');
  b.writeln('**How to get there**\n');
  final steps = reachSteps(f);
  for (var i = 0; i < steps.length; i++) {
    b.writeln('${i + 1}. ${steps[i]}');
  }
  b.writeln();
  final needs = needsLines(f);
  if (needs.isNotEmpty) {
    b.writeln('**You need**\n');
    for (final n in needs) {
      b.writeln('- $n');
    }
    b.writeln();
  }
  if (f['action'] != '-') b.writeln('**What it does:** ${f['action']}\n');
  if (f['expect'] != '-') b.writeln("**What you'll see:** ${f['expect']}\n");
  final children = names.entries
      .where((e) => e.key.startsWith('${f.id}/') && !e.key.substring(f.id.length + 1).contains('/'))
      .map((e) => e.value)
      .toList();
  if (children.isNotEmpty) {
    b.writeln('**In here**\n');
    for (final c in children) {
      b.writeln('- [[$c]]');
    }
    b.writeln();
  }
  if (f['keywords'] != '-') b.writeln('_Also searched as: ${f['keywords']}_\n');
  b.writeln('---\n<sub>Generated from the Sisu Mate feature map. Edits made here are overwritten.</sub>');
  return b.toString();
}

String _tree(List<Feature> published, Map<String, String> names) {
  final b = StringBuffer();
  for (final f in published) {
    final depth = f.id == 'home' ? 0 : f.id.split('/').length - (f.root == 'home' ? 2 : 1);
    b.writeln('${'  ' * depth.clamp(0, 12)}- [[${names[f.id]}]]');
  }
  return b.toString();
}

/// Renders all pages: `{fileName: content}` including `Home.md` and `_Sidebar.md`.
Map<String, String> renderWiki(List<Feature> features) {
  final byId = {for (final f in features) f.id: f};
  final published = features.where(isPublished).toList();
  for (final f in published) {
    leakCheck(f);
  }
  final names = <String, String>{};
  for (final f in published) {
    final name = pageName(f, byId);
    final clash = names.entries.where((e) => e.value == name).map((e) => e.key);
    if (clash.isNotEmpty) {
      throw FeatureMapError('${f.id} and ${clash.first} both publish as "$name"');
    }
    names[f.id] = name;
  }
  final pages = <String, String>{
    for (final f in published) '${names[f.id]}.md': renderPage(f, byId, names),
  };
  final tree = _tree(published, names);
  pages['Home.md'] = '# Sisu Mate help\n\n'
      'Every feature of the Sisu Mate sailing app: where it is, how to get there, and what it needs. '
      'Use the wiki search box, or browse below.\n\n'
      '${published.isEmpty ? '_No features published yet._\n' : tree}\n'
      '---\n<sub>Generated from the Sisu Mate feature map. Edits made here are overwritten.</sub>\n';
  pages['_Sidebar.md'] = '**[[Home]]**\n\n$tree';
  return pages;
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/feature_map_wiki.dart <out-dir> [<feature-map-root>]');
    exit(64);
  }
  final out = Directory(args[0]);
  final root = Directory(args.length > 1 ? args[1] : '.ai_context/feature_map');
  try {
    final pages = renderWiki(loadFeatures(root));
    out.createSync(recursive: true);
    for (final e in pages.entries) {
      File('${out.path}/${e.key}').writeAsStringSync(e.value);
    }
    stdout.writeln('wiki: ${pages.length} pages → ${out.path}');
  } on FeatureMapError catch (e) {
    stderr.writeln('wiki: $e');
    exit(1);
  }
}
