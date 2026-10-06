import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sisu_mate/core/app_router.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/ui/components/common_drawer.dart';

import 'feature_map/_reach.dart';

/// #141 — "Boat account" / "Join a boat" drawer tiles must navigate with
/// context.push (not context.go), so the destination screen's automatic
/// AppBar back arrow has a route to pop back to. Regression-tests the
/// navigation *type*, not the real destination screens (heavy Supabase/auth
/// dependencies unrelated to this bug) — a stub route is enough to observe
/// whether the back stack is left poppable.
void main() {
  Future<GoRouter> pumpDrawer(WidgetTester tester, String destination) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => Scaffold(
            endDrawer: const Drawer(child: AccountSection()),
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  child: const Text('open drawer'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: destination,
          builder: (context, state) =>
              const Scaffold(body: Text('destination stub')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('open drawer'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('"Boat account" tile leaves Home poppable (push, not go)',
      (tester) async {
    await pumpDrawer(tester, AppRoutes.accountSetup);

    await tester.tap(find.text('Boat account'));
    await tester.pumpAndSettle();

    expect(find.text('destination stub'), findsOneWidget);
    final context = tester.element(find.text('destination stub'));
    expect(Navigator.of(context).canPop(), isTrue,
        reason: 'context.push (not go) must leave Home poppable so the '
            'destination screen\'s default AppBar back arrow renders (#141)');
  });

  testWidgets('"Join a boat" tile leaves Home poppable (push, not go)',
      (tester) async {
    await pumpDrawer(tester, AppRoutes.joinBoat);

    await tester.tap(find.text('Join a boat'));
    await tester.pumpAndSettle();

    expect(find.text('destination stub'), findsOneWidget);
    final context = tester.element(find.text('destination stub'));
    expect(Navigator.of(context).canPop(), isTrue,
        reason: 'context.push (not go) must leave Home poppable so the '
            'destination screen\'s default AppBar back arrow renders (#141)');
  });

  // #401: module drawers used to carry their own magic-link "Sign In" tile
  // and About dialog; every menu must show the shared sections instead.
  for (final (id, steps, extra) in [
    ('home/checklists/checklist/complete_all', 3, null),
    ('home/safety/briefing/complete_all', 3, null),
    ('home/maintenance/schedule', null, 'tip:Menu'),
    ('home/drawer/settings/sign_in', null, null),
  ]) {
    testWidgets('$id menu uses the shared Account + About sections (#401)', (tester) async {
      await reach(tester, id, steps: steps);
      if (extra != null) await runStep(tester, extra);
      expect(find.byType(AccountSection), findsOneWidget);
      expect(find.text('Boat account'), findsOneWidget);
      expect(find.text('Join a boat'), findsOneWidget);
      expect(find.text('Sync data (Pro only)'), findsNothing);
      expect(find.text('Sign in to sync data (Pro only)'), findsNothing);
      if (!id.contains('settings')) expect(find.byType(AboutSection), findsOneWidget);
    });
  }
}
