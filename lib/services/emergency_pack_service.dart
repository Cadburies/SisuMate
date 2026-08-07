import '../models/models.dart';

/// #297 — offline emergency pack: ICE contacts + document expiry countdown.
class DocumentExpiryInfo {
  final Document document;
  final int daysUntilExpiry;
  final bool expired;

  const DocumentExpiryInfo({
    required this.document,
    required this.daysUntilExpiry,
    required this.expired,
  });
}

class EmergencyPackSummary {
  final List<CrewMember> iceCrew;
  final List<DocumentExpiryInfo> expiringDocs;
  final List<String> lines;

  const EmergencyPackSummary({
    required this.iceCrew,
    required this.expiringDocs,
    required this.lines,
  });

  bool get hasContent => lines.isNotEmpty;
}

class EmergencyPackService {
  EmergencyPackService._();

  /// Days ahead to surface "expiring soon" (inclusive).
  static const int expiryWatchDays = 90;

  /// Documents with an expiry within [watchDays] or already expired.
  static List<DocumentExpiryInfo> expiringDocuments(
    Iterable<Document> documents, {
    DateTime? now,
    int watchDays = expiryWatchDays,
  }) {
    final at = (now ?? DateTime.now()).toUtc();
    final day = DateTime.utc(at.year, at.month, at.day);
    final out = <DocumentExpiryInfo>[];
    for (final d in documents) {
      final exp = d.expiry?.toUtc();
      if (exp == null) continue;
      final expDay = DateTime.utc(exp.year, exp.month, exp.day);
      final days = expDay.difference(day).inDays;
      if (days <= watchDays) {
        out.add(DocumentExpiryInfo(
          document: d,
          daysUntilExpiry: days,
          expired: days < 0,
        ));
      }
    }
    out.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return out;
  }

  /// Crew rows that have an ICE contact filled in.
  static List<CrewMember> iceContacts(Iterable<CrewMember> crew) {
    return crew
        .where((c) => (c.iceContact ?? '').trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Airplane-mode friendly summary (text lines; UI/PDF can render later).
  static EmergencyPackSummary build({
    required List<CrewMember> crew,
    required List<Document> documents,
    DateTime? now,
  }) {
    final ice = iceContacts(crew);
    final docs = expiringDocuments(documents, now: now);
    final lines = <String>[];
    if (ice.isEmpty && docs.isEmpty) {
      return EmergencyPackSummary(iceCrew: ice, expiringDocs: docs, lines: lines);
    }
    lines.add('Sisu Mate emergency pack (offline)');
    if (ice.isNotEmpty) {
      lines.add('');
      lines.add('ICE / crew contacts:');
      for (final c in ice) {
        lines.add('• ${c.name} (${c.role}): ${c.iceContact!.trim()}'
            '${c.phone != null && c.phone!.trim().isNotEmpty ? ' · ${c.phone}' : ''}');
      }
    }
    if (docs.isNotEmpty) {
      lines.add('');
      lines.add('Documents expiring / expired (≤$expiryWatchDays d):');
      for (final e in docs) {
        final d = e.document;
        if (e.expired) {
          lines.add('• ${d.title} (${d.type}) — EXPIRED ${-e.daysUntilExpiry}d ago');
        } else if (e.daysUntilExpiry == 0) {
          lines.add('• ${d.title} (${d.type}) — expires today');
        } else {
          lines.add(
              '• ${d.title} (${d.type}) — expires in ${e.daysUntilExpiry}d');
        }
      }
    }
    return EmergencyPackSummary(iceCrew: ice, expiringDocs: docs, lines: lines);
  }
}
