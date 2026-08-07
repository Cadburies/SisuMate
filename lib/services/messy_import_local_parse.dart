import 'dart:convert';

import 'import_service.dart';

/// #302 — offline CSV / line-list → Sisu Mate import envelope (no LLM).
///
/// Handles shopping, inventory, and checklist-shaped pastes. Freeform prose
/// returns null so the caller can fall back to optional online LLM.
class MessyImportLocalParse {
  MessyImportLocalParse._();

  /// Attempt local parse. Returns JSON string matching [ImportService.parse]
  /// envelope, or null if the text looks like freeform prose / empty.
  static String? tryParseEnvelope(String raw, {required String kind}) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    // Already valid import JSON?
    if (text.startsWith('{') && text.contains('sisuMateImport')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded['sisuMateImport'] != null) {
          return text;
        }
      } catch (_) {}
    }

    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    // Heuristic: freeform prose (long lines, few list markers) → not local.
    final avgLen =
        lines.map((l) => l.length).reduce((a, b) => a + b) / lines.length;
    final listLike = lines.where(_looksLikeListLine).length;
    if (avgLen > 80 && listLike < lines.length * 0.5) {
      return null;
    }

    final items = <Map<String, dynamic>>[];
    final delimiter = _sniffDelimiter(lines.first);

    // Header row?
    var start = 0;
    List<String>? headers;
    if (delimiter != null && _looksLikeHeader(lines.first, delimiter)) {
      headers = _split(lines.first, delimiter);
      start = 1;
    }

    for (var i = start; i < lines.length; i++) {
      final line = lines[i].replaceFirst(RegExp(r'^[-*•]\s*'), '');
      if (line.isEmpty) continue;
      final map = _rowToItem(
        line: line,
        kind: kind,
        delimiter: delimiter,
        headers: headers,
      );
      if (map != null) items.add(map);
    }

    if (items.isEmpty) return null;

    return jsonEncode({
      'sisuMateImport': ImportService.formatVersion,
      'kind': kind,
      'items': items,
    });
  }

  static bool _looksLikeListLine(String line) {
    if (line.startsWith(RegExp(r'[-*•]'))) return true;
    if (line.contains(',') || line.contains('\t') || line.contains(';')) {
      return true;
    }
    // short noun-ish lines
    return line.length <= 60 && !line.endsWith('.');
  }

  static String? _sniffDelimiter(String sample) {
    if (sample.contains('\t')) return '\t';
    if (sample.split(',').length >= 2) return ',';
    if (sample.split(';').length >= 2) return ';';
    return null;
  }

  static bool _looksLikeHeader(String line, String delim) {
    final lower = line.toLowerCase();
    return lower.contains('name') ||
        lower.contains('title') ||
        lower.contains('item') ||
        lower.contains('qty') ||
        lower.contains('quantity') ||
        lower.contains('category');
  }

  static List<String> _split(String line, String delim) =>
      line.split(delim).map((s) => s.trim().replaceAll(RegExp(r'^"|"$'), '')).toList();

  static Map<String, dynamic>? _rowToItem({
    required String line,
    required String kind,
    required String? delimiter,
    required List<String>? headers,
  }) {
    if (delimiter != null) {
      final cols = _split(line, delimiter);
      if (headers != null && headers.length == cols.length) {
        final byHeader = <String, String>{};
        for (var i = 0; i < headers.length; i++) {
          byHeader[headers[i].toLowerCase()] = cols[i];
        }
        return _fromHeaderMap(byHeader, kind);
      }
      // No header: col0=name, col1=qty?, col2=unit?/category?
      if (cols.isEmpty || cols.first.isEmpty) return null;
      return _fromColumns(cols, kind);
    }

    // Single-column line: whole line is name/title
    switch (kind) {
      case ImportService.kindShopping:
        return {'name': line, 'category': 'General'};
      case ImportService.kindInventory:
        return {'name': line, 'quantity': 1};
      case ImportService.kindChecklist:
        return {'title': line};
      case ImportService.kindMaintenance:
        return {'description': line};
      case ImportService.kindCrew:
        return {'name': line};
      case ImportService.kindDocument:
        return {'title': line, 'type': 'Other'};
      default:
        return null;
    }
  }

  static Map<String, dynamic>? _fromHeaderMap(
    Map<String, String> h,
    String kind,
  ) {
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = h[k];
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    final name = pick(['name', 'item', 'title', 'description', 'product']);
    if (name == null) return null;
    final qty = double.tryParse(pick(['quantity', 'qty', 'amount', 'count']) ?? '');
    final unit = pick(['unit', 'uom']);
    final category = pick(['category', 'cat', 'group', 'location']);

    switch (kind) {
      case ImportService.kindShopping:
        return {
          'name': name,
          'category': category ?? 'General',
          'quantity': ?qty,
          'unit': ?unit,
        };
      case ImportService.kindInventory:
        return {
          'name': name,
          'location': ?category,
          'quantity': qty ?? 1,
          'unit': ?unit,
        };
      case ImportService.kindChecklist:
        return {'title': name};
      case ImportService.kindMaintenance:
        return {'description': name};
      default:
        return {'name': name};
    }
  }

  static Map<String, dynamic> _fromColumns(List<String> cols, String kind) {
    final name = cols[0];
    final qty = cols.length > 1 ? double.tryParse(cols[1]) : null;
    final third = cols.length > 2 ? cols[2] : null;
    switch (kind) {
      case ImportService.kindShopping:
        return {
          'name': name,
          'category': third ?? 'General',
          'quantity': ?qty,
          'unit': third != null && qty == null
              ? third
              : (qty != null && cols.length > 3 ? cols[3] : null),
        };
      case ImportService.kindInventory:
        return {
          'name': name,
          'quantity': qty ?? 1,
          'location': ?third,
        };
      case ImportService.kindChecklist:
        return {'title': name};
      case ImportService.kindMaintenance:
        return {'description': name};
      default:
        return {'name': name};
    }
  }
}
