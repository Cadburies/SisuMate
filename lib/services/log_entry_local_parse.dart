import '../models/models.dart';

/// #287 — offline freeform Captain's Log parse (regex/heuristics).
///
/// Produces a partial [CaptainLogEntry] without network. Callers may run an
/// optional LLM pass when online; this path must always work offline first.
class LogEntryLocalParse {
  LogEntryLocalParse._();

  /// Parse sailor freeform text into structured fields.
  ///
  /// Recognizes wind speed/direction, SOG, rough weather words, and keeps
  /// the full freeform as [CaptainLogEntry.notes]. Missing fields stay null.
  static CaptainLogEntry parse(String freeform) {
    final text = freeform.trim();
    final entry = CaptainLogEntry();
    if (text.isEmpty) return entry;

    entry.notes = text;

    // Wind speed: "12kt", "12 kt", "12 knots", "TWS 15"
    final windSpeed = RegExp(
      r'(?:tws\s*[:=]?\s*)?(\d{1,2}(?:\.\d+)?)\s*(?:kt|kts|kn|knots)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (windSpeed != null) {
      entry.windSpeedKt = double.tryParse(windSpeed.group(1)!)?.round();
    }

    // Wind direction: "SW breeze", "from NE", "wind NNE", "bearing 220"
    final windDirWord = RegExp(
      r'\b(?:from\s+)?(N|NNE|NE|ENE|E|ESE|SE|SSE|S|SSW|SW|WSW|W|WNW|NW|NNW)\b'
      r'(?:\s+(?:breeze|wind|gusts?))?',
      caseSensitive: false,
    ).firstMatch(text);
    if (windDirWord != null) {
      entry.windDir = windDirWord.group(1)!.toUpperCase();
    } else {
      final fromDeg = RegExp(
        r'\b(?:wind|from)\s+(\d{1,3})\s*°?',
        caseSensitive: false,
      ).firstMatch(text);
      if (fromDeg != null) {
        entry.windDir = '${fromDeg.group(1)}°';
      }
    }

    // SOG: "SOG 5.2", "making 6 kn"
    final sog = RegExp(
      r'\bsog\s*[:=]?\s*(\d{1,2}(?:\.\d+)?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (sog != null) {
      entry.sogKt = double.tryParse(sog.group(1)!);
    }

    // Position: 12.05N 61.75W or 12°03'N
    final pos = RegExp(
      r"(-?\d{1,2}(?:\.\d+)?)\s*([NnSs])\s*[,\s]+(-?\d{1,3}(?:\.\d+)?)\s*([EeWw])",
    ).firstMatch(text);
    if (pos != null) {
      var lat = double.tryParse(pos.group(1)!);
      var lon = double.tryParse(pos.group(3)!);
      if (lat != null && lon != null) {
        if (pos.group(2)!.toUpperCase() == 'S') lat = -lat.abs();
        if (pos.group(2)!.toUpperCase() == 'N') lat = lat.abs();
        if (pos.group(4)!.toUpperCase() == 'W') lon = -lon.abs();
        if (pos.group(4)!.toUpperCase() == 'E') lon = lon.abs();
        entry.positionLat = lat;
        entry.positionLng = lon;
      }
    }

    // Weather keywords → short weather label
    final lower = text.toLowerCase();
    final weatherBits = <String>[];
    for (final w in const [
      'sunny',
      'clear',
      'cloudy',
      'overcast',
      'rain',
      'squall',
      'storm',
      'fog',
      'haze',
      'calm',
      'chop',
      'swell',
    ]) {
      if (lower.contains(w)) weatherBits.add(w);
    }
    if (weatherBits.isNotEmpty) {
      entry.weather = weatherBits.join(', ');
    }

    // Sea state words
    if (RegExp(r'\b(rough|moderate|smooth|calm)\s*(seas?|water)?\b',
            caseSensitive: false)
        .hasMatch(text)) {
      final m = RegExp(r'\b(rough|moderate|smooth|calm)\b', caseSensitive: false)
          .firstMatch(text);
      entry.seaState = m?.group(1)?.toLowerCase();
    }

    // Time-ish: "around 0800", "at 14:30"
    final time = RegExp(r'\b(?:at|around|@)\s*(\d{1,2}:\d{2}|\d{3,4})\b',
            caseSensitive: false)
        .firstMatch(text);
    if (time != null) {
      var t = time.group(1)!;
      if (!t.contains(':') && t.length >= 3) {
        final padded = t.padLeft(4, '0');
        t = '${padded.substring(0, 2)}:${padded.substring(2)}';
      }
      entry.logTime = t;
    }

    // Title: first ~48 chars of first sentence, cleaned
    final firstLine = text.split(RegExp(r'[\n.!?]')).first.trim();
    if (firstLine.isNotEmpty) {
      entry.title = firstLine.length > 48
          ? '${firstLine.substring(0, 45).trim()}…'
          : firstLine;
    }

    return entry;
  }

  /// True when local parse extracted at least one field beyond notes/title.
  /// Title alone is not enough — almost any text gets a title snip.
  static bool hasStructuredFields(CaptainLogEntry e) {
    return e.windSpeedKt != null ||
        e.windDir != null ||
        e.sogKt != null ||
        e.positionLat != null ||
        e.weather != null ||
        e.seaState != null ||
        e.logTime != null;
  }
}
