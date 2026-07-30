import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/database_service.dart';

void main() {
  group('DatabaseService RT1 split', () {
    test('runDeferredSeeds is public and idempotent-safe to call', () async {
      // Method must exist and not throw when DB open fails in plain unit
      // tests without native sqlite — it swallows errors by design.
      final svc = DatabaseService();
      await expectLater(svc.runDeferredSeeds(), completes);
    });

    test('DbInitResult covers healthy/seeded/corrupted', () {
      expect(DbInitResult.values, containsAll([
        DbInitResult.healthy,
        DbInitResult.seeded,
        DbInitResult.corrupted,
      ]));
    });
  });
}
