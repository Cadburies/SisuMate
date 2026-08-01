import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/profile_heartbeat.dart';

import 'test_helpers/fake_auth_backend.dart';

void main() {
  tearDown(ProfileHeartbeat.resetDebugHooks);

  group('ProfileHeartbeat.stamp', () {
    test('no-ops when there is no signed-in user', () async {
      final upserts = <Map<String, dynamic>>[];
      ProfileHeartbeat.debugCurrentUser = () async => null;
      ProfileHeartbeat.debugUpsertProfile = (row) async => upserts.add(row);

      await ProfileHeartbeat.stamp();
      expect(upserts, isEmpty);
    });

    test('no-ops for anonymous users', () async {
      final upserts = <Map<String, dynamic>>[];
      ProfileHeartbeat.debugCurrentUser =
          () async => fakeOwnerUser(isAnonymous: true);
      ProfileHeartbeat.debugUpsertProfile = (row) async => upserts.add(row);

      await ProfileHeartbeat.stamp();
      expect(upserts, isEmpty);
    });

    test('upserts lastSeenAt and proUntil for an owner', () async {
      final upserts = <Map<String, dynamic>>[];
      final proUntil = DateTime.utc(2030, 1, 15);
      ProfileHeartbeat.debugCurrentUser =
          () async => fakeOwnerUser(id: 'owner-42');
      ProfileHeartbeat.debugProExpiresAt = () async => proUntil;
      ProfileHeartbeat.debugUpsertProfile = (row) async => upserts.add(row);

      await ProfileHeartbeat.stamp();

      expect(upserts, hasLength(1));
      expect(upserts.single['id'], 'owner-42');
      expect(upserts.single['lastSeenAt'], isA<String>());
      expect(upserts.single['proUntil'], proUntil.toIso8601String());
    });

    test('omits proUntil when RevenueCat returns null', () async {
      final upserts = <Map<String, dynamic>>[];
      ProfileHeartbeat.debugCurrentUser = () async => fakeOwnerUser();
      ProfileHeartbeat.debugProExpiresAt = () async => null;
      ProfileHeartbeat.debugUpsertProfile = (row) async => upserts.add(row);

      await ProfileHeartbeat.stamp();

      expect(upserts.single.containsKey('proUntil'), isFalse);
      expect(upserts.single['lastSeenAt'], isNotNull);
    });

    test('swallows backend failures (best-effort)', () async {
      ProfileHeartbeat.debugCurrentUser = () async => fakeOwnerUser();
      ProfileHeartbeat.debugProExpiresAt = () async => null;
      ProfileHeartbeat.debugUpsertProfile =
          (row) async => throw Exception('offline');

      await expectLater(ProfileHeartbeat.stamp(), completes);
    });
  });
}
