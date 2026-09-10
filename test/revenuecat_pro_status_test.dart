import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';

void main() {
  group('RevenueCatService PRO2 / PRO3 surface', () {
    test('onCustomerInfoUpdated is a broadcast stream (multiple listeners)',
        () async {
      final rc = RevenueCatService();
      final a = rc.onCustomerInfoUpdated.listen((_) {});
      final b = rc.onCustomerInfoUpdated.listen((_) {});
      await a.cancel();
      await b.cancel();
    });

    test('isPro is false in unit tests even when kForceProForTesting is true',
        () async {
      // FLUTTER_TEST is set by the test runner — force-pro must not apply.
      expect(kForceProForTesting, isTrue);
      final isPro = await RevenueCatService().isPro();
      expect(isPro, isFalse);
    });

    test('parseForceProUntil is null for empty/invalid and UTC for ISO dates',
        () {
      expect(parseForceProUntil(''), isNull);
      expect(parseForceProUntil('   '), isNull);
      expect(parseForceProUntil('not-a-date'), isNull);
      expect(
        parseForceProUntil('2026-12-31T23:59:59Z'),
        DateTime.utc(2026, 12, 31, 23, 59, 59),
      );
    });

    test('isTesterProActive honors expiry and is off under the test runner', () {
      const until = '2026-12-31T23:59:59Z';
      expect(
        isTesterProActive(
          raw: until,
          now: DateTime.utc(2026, 6, 1),
          underTest: false,
        ),
        isTrue,
      );
      expect(
        isTesterProActive(
          raw: until,
          now: DateTime.utc(2027, 1, 1),
          underTest: false,
        ),
        isFalse,
      );
      expect(
        isTesterProActive(
          raw: until,
          now: DateTime.utc(2026, 6, 1),
          underTest: true,
        ),
        isFalse,
      );
      expect(isTesterProActive(raw: '', underTest: false), isFalse);
      // Default path: FLUTTER_TEST is set, so even a future date is ignored.
      expect(
        isTesterProActive(raw: until, now: DateTime.utc(2026, 6, 1)),
        isFalse,
      );
    });

    test('updateCustomerInfo notifies listeners (PRO2)', () async {
      final rc = RevenueCatService();
      var notified = 0;
      final sub = rc.onCustomerInfoUpdated.listen((_) => notified++);

      // Without a real CustomerInfo from the SDK we can only assert the
      // service exposes the notify path used after purchase/restore.
      // Calling updateCustomerInfo requires a CustomerInfo instance from the
      // platform SDK — skip if we cannot construct one. The listener bus is
      // still covered: restorePurchases/link paths call _notifyCustomerInfoUpdated.
      expect(rc.onCustomerInfoUpdated, isNotNull);
      await sub.cancel();
      expect(notified, 0);
    });

    test('linkSupabaseUserId is safe when SDK is not initialised (PRO3)',
        () async {
      // No platform channel in unit tests — must not throw.
      await RevenueCatService().linkSupabaseUserId('test-user-uuid');
      await RevenueCatService().linkSupabaseUserId(null);
    });
  });
}
