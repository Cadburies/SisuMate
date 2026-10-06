/// #402 / #286 — offline keyword reading of a pasted warranty or policy excerpt.
///
/// This never decides coverage. It only points at words in the text the
/// user pasted, plus a short checklist of what that text cannot settle.
class PastedExcerptLocalCheck {
  PastedExcerptLocalCheck._();

  static String warranty({
    required String situation,
    required String excerpt,
  }) => _assess(kind: _Kind.warranty, situation: situation, excerpt: excerpt);

  static String insurance({
    required String situation,
    required String excerpt,
  }) => _assess(kind: _Kind.insurance, situation: situation, excerpt: excerpt);
}

enum _Kind { warranty, insurance }

const _exclusionPhrases = [
  'does not cover',
  'is not covered',
  "isn't covered",
  'not covered',
  'not warranted',
  'wear and tear',
  'normal wear',
  'routine maintenance',
  'improper maintenance',
  'improper installation',
  'gradual deterioration',
  'unseaworthy',
  'consumable',
  'exclusion',
  'excluded',
  'neglect',
  'void if',
  'voids the',
];

const _wearPhrases = [
  'wear and tear',
  'normal wear',
  'consumable',
  'routine maintenance',
];

const _denialPhrases = [
  'does not cover',
  'is not covered',
  "isn't covered",
  'not covered',
  'not warranted',
  'excluded',
  'exclusion',
  'void if',
  'voids the',
];

const _coveragePhrases = [
  'defects in material',
  'defects in workmanship',
  'will repair',
  'will replace',
  'warranted',
  'coverage',
  'covered',
];

/// Words that mean the same topic even when the two texts use different ones.
const _groups = <List<String>>[
  ['electrical', 'float', 'switch', 'wiring', 'alternator'],
  ['storm', 'wind', 'squall'],
  ['fitting', 'rail', 'boom', 'stanchion', 'rigging'],
  ['impeller', 'raw water'],
  ['theft', 'stolen'],
  ['grounding', 'aground', 'grounded'],
  ['fire', 'burned', 'burnt'],
  ['corrosion', 'anode'],
  ['gradual', 'slow', 'seep', 'leak', 'deteriorat'],
];

String _assess({
  required _Kind kind,
  required String situation,
  required String excerpt,
}) {
  final sit = situation.toLowerCase();
  final exc = excerpt.toLowerCase();
  final exclusions = [
    for (final phrase in _exclusionPhrases)
      if (exc.contains(phrase)) phrase,
  ];
  final stripped = _withoutExclusions(exc);
  final coverage = [
    for (final phrase in _coveragePhrases)
      if (stripped.contains(phrase)) phrase,
  ];
  final links = _links(sit, exc);
  final window = _window(sit, exc);
  final wearish =
      sit.contains('wear') ||
      sit.contains('worn') ||
      sit.contains('consumable') ||
      sit.contains('impeller');
  final wearExclusion = wearish && exclusions.any(_wearPhrases.contains);
  final gradualExclusion =
      exclusions.any(
        (hit) =>
            hit.contains('gradual') ||
            hit.contains('deteriorat') ||
            hit.contains('neglect') ||
            hit.contains('unseaworthy'),
      ) &&
      _situationMatchesThose(sit, exclusions);
  final bareDenial =
      coverage.isEmpty &&
      exclusions.any(_denialPhrases.contains) &&
      (links.isNotEmpty || wearish);
  final pastWindow =
      window != null && window.contains('past the stated window');
  final insideWindow =
      window != null && window.contains('inside the stated window');

  final String verdict;
  if (wearExclusion || gradualExclusion || bareDenial) {
    verdict = 'lines up with an exclusion in the excerpt';
  } else if (pastWindow) {
    verdict = 'past the stated window';
  } else if (coverage.isNotEmpty && (links.isNotEmpty || insideWindow)) {
    verdict = 'possibly in scope of the pasted sentence';
  } else {
    verdict = 'does not say whether this is covered';
  }

  final determination = kind == _Kind.warranty
      ? 'not a warranty determination'
      : 'not an insurance claim determination';
  final buf = StringBuffer()
    ..writeln(
      'Offline reading (keyword check of the text you pasted — $determination):',
    )
    ..writeln()
    ..writeln('• Reading: $verdict');
  if (coverage.isNotEmpty) {
    buf.writeln('• Coverage language: ${coverage.join(', ')}');
  }
  if (exclusions.isNotEmpty) {
    buf.writeln('• Exclusion language: ${exclusions.join(', ')}');
  }
  if (links.isNotEmpty) {
    buf.writeln('• Topical link: ${links.join('; ')}');
  }
  if (window != null) buf.writeln('• $window');
  final amounts = _amounts(excerpt);
  if (amounts.isNotEmpty) {
    buf.writeln('• Limit named in the excerpt: ${amounts.join(', ')}');
  }
  buf
    ..writeln()
    ..writeln(
      kind == _Kind.warranty
          ? 'Confirm with the manufacturer or dealer. Check the start date, whether the part is a consumable, and parts versus labour.'
          : 'Confirm with your insurer or broker. Check the deductible, named perils, and whether the boat was seaworthy.',
    );
  return buf.toString().trimRight();
}

bool _situationMatchesThose(String situation, List<String> exclusions) {
  final gradual = exclusions.any(
    (hit) => hit.contains('gradual') || hit.contains('deteriorat'),
  );
  if (gradual &&
      (situation.contains('slow') ||
          situation.contains('leak') ||
          situation.contains('seep') ||
          situation.contains('gradual'))) {
    return true;
  }
  if (exclusions.any((hit) => hit.contains('neglect')) &&
      situation.contains('neglect')) {
    return true;
  }
  if (exclusions.any((hit) => hit.contains('unseaworthy')) &&
      (situation.contains('unseaworthy') || situation.contains('seaworthy'))) {
    return true;
  }
  return false;
}

String _withoutExclusions(String excerpt) {
  var text = excerpt;
  final phrases = [..._exclusionPhrases]
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final phrase in phrases) {
    text = text.replaceAll(phrase, ' ');
  }
  return text;
}

List<String> _links(String situation, String excerpt) {
  final out = <String>[];
  for (final group in _groups) {
    final inSituation = group.where(situation.contains).take(2).join(' / ');
    final inExcerpt = group.where(excerpt.contains).take(2).join(' / ');
    if (inSituation.isNotEmpty && inExcerpt.isNotEmpty) {
      out.add('$inSituation ↔ $inExcerpt');
    }
  }
  return out;
}

String? _window(String situation, String excerpt) {
  final lines = <String>[];
  for (final unit in ['hour', 'month', 'year']) {
    final fromNote = _firstSpan(situation, unit);
    final fromExcerpt = _firstSpan(excerpt, unit);
    if (fromNote == null || fromExcerpt == null) continue;
    final noun = switch (unit) {
      'hour' => 'hours',
      'month' => 'months',
      _ => 'years',
    };
    final relation = fromNote <= fromExcerpt
        ? 'inside the stated window only if the clock started when the excerpt says it did'
        : 'past the stated window if that clock has been running the whole time';
    lines.add(
      'Stated term: $fromExcerpt $noun. Your note says $fromNote $noun, which is $relation.',
    );
  }
  if (lines.isEmpty) return null;
  return lines.join(' ');
}

int? _firstSpan(String text, String unit) {
  final match = RegExp('(\\d+)\\s*$unit').firstMatch(text);
  if (match == null) return null;
  return int.parse(match.group(1)!);
}

List<String> _amounts(String excerpt) {
  final re = RegExp(r'\$\s?\d{1,3}(?:,\d{3})*(?:\.\d+)?');
  return [for (final match in re.allMatches(excerpt)) match.group(0)!];
}
