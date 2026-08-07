/// #290 — offline compliance packs (deterministic tables, not LLM).
///
/// Non-legal-advice checklists/reminders. Optional LLM remains available
/// when the user pastes a full manual excerpt and is online.
class ComplianceHit {
  final String ruleId;
  final String severity; // pass | warn | fail | info
  final String title;
  final String detail;

  const ComplianceHit({
    required this.ruleId,
    required this.severity,
    required this.title,
    required this.detail,
  });
}

class CompliancePackService {
  CompliancePackService._();

  /// Safety-equipment rules (bundled v1 — Caribbean / general yacht).
  static List<ComplianceHit> matchSafetyItem(String description) {
    final d = description.toLowerCase();
    final hits = <ComplianceHit>[];

    void add(String id, String sev, String title, String detail) {
      hits.add(ComplianceHit(
        ruleId: id,
        severity: sev,
        title: title,
        detail: detail,
      ));
    }

    if (d.contains('flare') || d.contains('pyrotechnic')) {
      add(
        'flare_expiry',
        'warn',
        'Flares — check expiry & SOLAS category',
        'Handheld and parachute flares typically expire 3 years from '
            'manufacture. Confirm date stamps and keep a sealed dry pack. '
            'Not a certified inspection.',
      );
    }
    if (d.contains('life raft') || d.contains('liferaft') || d.contains('raft')) {
      add(
        'liferaft_service',
        'warn',
        'Life raft — service interval',
        'Most yachts service life rafts annually or per manufacturer '
            '(often 12–36 months). Check hydrostatic release expiry too.',
      );
    }
    if (d.contains('epirb') || d.contains('plb')) {
      add(
        'epirb_reg',
        'warn',
        'EPIRB/PLB — registration & battery',
        'Confirm MMSI/registration is current and battery/self-test is in date. '
            'Hydrostatic release has its own expiry.',
      );
    }
    if (d.contains('fire extinguisher') || d.contains('extinguisher')) {
      add(
        'extinguisher',
        'warn',
        'Fire extinguisher — gauge & service',
        'Check pressure gauge in green, pin/seal intact, and service tag. '
            'Engine-room extinguishers often have shorter intervals.',
      );
    }
    if (d.contains('lifejacket') ||
        d.contains('life jacket') ||
        d.contains('pfd')) {
      add(
        'pfd',
        'info',
        'Lifejackets / PFDs',
        'Inspect bladder, oral tube, light, and crotch strap. Service '
            'inflatable jackets per maker (often annual).',
      );
    }
    if (d.contains('gas') || d.contains('lpg') || d.contains('propane')) {
      add(
        'lpg',
        'fail',
        'LPG / gas system',
        'Treat gas faults as urgent: sniffer, locker drain, hose age, and '
            'regulator. Prefer a gas-safe technician for leaks.',
      );
    }

    if (hits.isEmpty) {
      add(
        'generic',
        'info',
        'No bundled rule matched',
        'Offline pack has no specific rule for this description. Paste a '
            'manual excerpt and use AI when online, or add the service date '
            'to your safety checklist.',
      );
    }
    return hits;
  }

  /// Coarse Caribbean customs red-flags (non-legal).
  static List<ComplianceHit> matchCustomsItem(String description) {
    final d = description.toLowerCase();
    final hits = <ComplianceHit>[];
    void add(String id, String sev, String title, String detail) {
      hits.add(ComplianceHit(
        ruleId: id,
        severity: sev,
        title: title,
        detail: detail,
      ));
    }

    if (d.contains('drone') || d.contains('uav') || d.contains('quadcopter')) {
      add(
        'drone',
        'fail',
        'Drones often restricted',
        'Many Caribbean states restrict or ban recreational drones without '
            'prior permission. Check local CAA rules before packing.',
      );
    }
    if (d.contains('spear') || d.contains('speargun') || d.contains('hawaiian')) {
      add(
        'spear',
        'warn',
        'Spearfishing gear',
        'Some islands restrict spearguns or require permits. Declare on '
            'clearance forms when unsure.',
      );
    }
    if (d.contains('meat') ||
        d.contains('chicken') ||
        d.contains('pork') ||
        d.contains('beef') ||
        d.contains('fresh produce') ||
        d.contains('fruit') ||
        d.contains('vegetable')) {
      add(
        'agri',
        'warn',
        'Fresh food / meat',
        'Agricultural restrictions are common. Prefer sealed commercial '
            'packaging; expect inspection of fresh produce and meat.',
      );
    }
    if (d.contains('alcohol') || d.contains('rum') || d.contains('wine') || d.contains('beer')) {
      add(
        'alcohol',
        'info',
        'Alcohol quantities',
        'Personal quantities are usually fine; large volumes may be dutiable. '
            'Keep receipts for bonded stores when applicable.',
      );
    }
    if (hits.isEmpty) {
      add(
        'generic',
        'info',
        'No red-flag keyword matched',
        'Offline pack found no special flag. Still declare accurately on '
            'clearance forms — this is not legal advice.',
      );
    }
    return hits;
  }

  static String formatHits(List<ComplianceHit> hits) {
    final buf = StringBuffer(
      'Offline compliance pack (reminders only — not a certified inspection '
      'or legal advice):\n',
    );
    for (final h in hits) {
      buf.writeln();
      buf.writeln('[${h.severity.toUpperCase()}] ${h.title}');
      buf.writeln(h.detail);
    }
    return buf.toString().trimRight();
  }
}
