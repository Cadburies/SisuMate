import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/compliance_pack_service.dart';

void main() {
  test('safety pack flags flares and epirb', () {
    final hits = CompliancePackService.matchSafetyItem(
      'Handheld flares expired? EPIRB self-test OK',
    );
    expect(hits.any((h) => h.ruleId == 'flare_expiry'), isTrue);
    expect(hits.any((h) => h.ruleId == 'epirb_reg'), isTrue);
    expect(CompliancePackService.formatHits(hits), contains('Offline'));
  });

  test('customs pack flags drones', () {
    final hits = CompliancePackService.matchCustomsItem('DJI mini drone');
    expect(hits.any((h) => h.ruleId == 'drone'), isTrue);
    expect(hits.first.severity, 'fail');
  });
}
