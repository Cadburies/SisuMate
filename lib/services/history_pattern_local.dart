/// #288 — offline recurring-theme detection over log/maintenance notes.
///
/// Token / co-occurrence analysis only (no LLM). Callers may optionally
/// request an LLM narrative when online; this path always works offline.
class HistoryPatternHit {
  /// Normalized theme token or short phrase.
  final String theme;

  /// How many distinct notes mention this theme.
  final int noteCount;

  /// Example dates (most recent first), capped.
  final List<DateTime> dates;

  const HistoryPatternHit({
    required this.theme,
    required this.noteCount,
    required this.dates,
  });
}

class HistoryPatternLocal {
  HistoryPatternLocal._();

  static const minNotes = 3;
  static const minOccurrences = 2;

  /// English-ish stopwords + tiny nautical noise (not themes).
  static const _stop = {
    'a', 'an', 'the', 'and', 'or', 'but', 'if', 'then', 'so', 'to', 'of', 'in',
    'on', 'at', 'for', 'from', 'with', 'without', 'as', 'is', 'was', 'were',
    'be', 'been', 'are', 'am', 'it', 'its', 'this', 'that', 'these', 'those',
    'i', 'we', 'you', 'they', 'he', 'she', 'our', 'my', 'me', 'us', 'them',
    'not', 'no', 'yes', 'ok', 'all', 'some', 'any', 'very', 'just', 'also',
    'too', 'than', 'into', 'over', 'under', 'after', 'before', 'about',
    'again', 'still', 'today', 'yesterday', 'tonight', 'morning', 'evening',
    'day', 'night', 'hours', 'hour', 'kt', 'kts', 'kn', 'nm', 'rpm',
  };

  /// Detect recurring tokens/bigrams across dated free-text notes.
  static List<HistoryPatternHit> detect(
    List<({DateTime date, String source, String text})> entries, {
    int minOccurrences = minOccurrences,
  }) {
    if (entries.length < minNotes) return const [];

    // theme → set of note indices that contain it
    final themeNotes = <String, Set<int>>{};
    final themeDates = <String, List<DateTime>>{};

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final tokens = _tokens(e.text);
      if (tokens.isEmpty) continue;
      final themes = <String>{...tokens};
      for (var t = 0; t + 1 < tokens.length; t++) {
        themes.add('${tokens[t]} ${tokens[t + 1]}');
      }
      for (final theme in themes) {
        themeNotes.putIfAbsent(theme, () => {}).add(i);
        themeDates.putIfAbsent(theme, () => []).add(e.date);
      }
    }

    final hits = <HistoryPatternHit>[];
    for (final e in themeNotes.entries) {
      final n = e.value.length;
      if (n < minOccurrences) continue;
      // Prefer multi-word / longer tokens over ultra-generic singles when
      // both appear; still keep singles that recur often.
      final dates = [...?themeDates[e.key]]
        ..sort((a, b) => b.compareTo(a));
      hits.add(HistoryPatternHit(
        theme: e.key,
        noteCount: n,
        dates: dates.take(6).toList(),
      ));
    }

    hits.sort((a, b) {
      final c = b.noteCount.compareTo(a.noteCount);
      if (c != 0) return c;
      // Prefer phrases (space) then longer tokens.
      final ap = a.theme.contains(' ') ? 1 : 0;
      final bp = b.theme.contains(' ') ? 1 : 0;
      final p = bp.compareTo(ap);
      if (p != 0) return p;
      return b.theme.length.compareTo(a.theme.length);
    });

    // Drop unigrams that are fully covered by a stronger bigram hit.
    final kept = <HistoryPatternHit>[];
    for (final h in hits) {
      if (!h.theme.contains(' ')) {
        final covered = hits.any((o) =>
            o.theme.contains(' ') &&
            o.theme.split(' ').contains(h.theme) &&
            o.noteCount >= h.noteCount);
        if (covered) continue;
      }
      kept.add(h);
      if (kept.length >= 12) break;
    }
    return kept;
  }

  /// Human-readable offline report (never empty string when [hits] non-empty).
  static String formatReport(List<HistoryPatternHit> hits) {
    if (hits.isEmpty) {
      return 'No recurring themes found in recent notes (local scan). '
          'Keep logging — patterns need the same issue mentioned more than once.';
    }
    final buf = StringBuffer(
        'Offline scan — recurring themes (not a diagnosis):\n');
    for (final h in hits) {
      final dateBits = h.dates
          .map((d) =>
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
          .toSet()
          .take(4)
          .join(', ');
      buf.writeln(
          '• "${h.theme}" — in ${h.noteCount} notes'
          '${dateBits.isEmpty ? '' : ' ($dateBits)'}');
    }
    buf.writeln(
        '\nInvestigate in person before acting. Optional AI can rephrase when online.');
    return buf.toString().trimRight();
  }

  static List<String> _tokens(String text) {
    final raw = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s\-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 3 && !_stop.contains(t))
        .toList();
    return raw;
  }
}
