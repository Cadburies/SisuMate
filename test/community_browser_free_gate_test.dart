import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/community/community_browser_screen.dart';

import 'test_helpers/fake_supabase_remote.dart';
import 'test_helpers/platform_mocks.dart';

/// Regression: Community browse/import is documented Pro-only
/// (.ai_context/access_tiers.md — "Community browse/import | no | yes"), and
/// the screen already hid the list behind an upgrade prompt for Free users —
/// but `_loadTemplates()` queried Supabase's community tables unconditionally
/// before that gate was ever checked, so a Free user still triggered a live
/// network call in the background on open and on every filter change.
class _CountingSupabaseRemote extends FakeSupabaseRemote {
  int browseCallCount = 0;

  @override
  Future<List<Map<String, dynamic>>> communityBrowse({
    String? category,
    String? subcategory,
    bool onlyApproved = true,
    required String orderColumn,
  }) async {
    browseCallCount++;
    return super.communityBrowse(
      category: category,
      subcategory: subcategory,
      onlyApproved: onlyApproved,
      orderColumn: orderColumn,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late _CountingSupabaseRemote remote;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = _CountingSupabaseRemote();
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseRemoteProvider.overrideWithValue(remote),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CommunityBrowserScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Free user opening Community never calls Supabase browse',
      (tester) async {
    RevenueCatService.debugProOverrideForTests = false;

    await pumpScreen(tester);

    expect(remote.browseCallCount, 0,
        reason: 'Free is fully gated (access_tiers.md) — must not query '
            'Supabase even in the background while showing the upgrade prompt');
  });

  testWidgets('Pro user opening Community still loads the list',
      (tester) async {
    RevenueCatService.debugProOverrideForTests = true;

    await pumpScreen(tester);

    expect(remote.browseCallCount, greaterThan(0),
        reason: 'gate must not regress the intended Pro browse flow');
  });
}
