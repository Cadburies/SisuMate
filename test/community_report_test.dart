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

/// #321 — Community's "Report" action end-to-end through the real screen +
/// repository, against a [FakeSupabaseRemote] (same TEST2 seam pattern as
/// `community_browser_free_gate_test.dart`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeSupabaseRemote remote;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeSupabaseRemote(userId: 'auth-uid-1');
    RevenueCatService.debugProOverrideForTests = true;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await remote.communityInsert({
      'id': 't1',
      'title': 'Engine checks',
      'name': 'engine_checks',
      'description': 'd',
      'category': 'maintenance',
      'subcategory': 'yanmar',
      'author_id': 'someone-else',
      'content': '{}',
      'is_approved': true,
    });
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

  testWidgets('reporting a template submits reason + note and confirms',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Report this template'));
    await tester.pumpAndSettle();

    expect(find.text('Report "Engine checks"'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Note (optional)'),
        'Step 3 is dangerous as written');
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(remote.reports, hasLength(1));
    expect(remote.reports.single.templateId, 't1');
    expect(remote.reports.single.userId, 'auth-uid-1');
    expect(remote.reports.single.note, 'Step 3 is dangerous as written');
    expect(find.textContaining('Reported'), findsOneWidget);
  });

  testWidgets('reporting can be cancelled without submitting anything',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Report this template'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(remote.reports, isEmpty);
  });
}
