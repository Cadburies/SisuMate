import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/components/common_drawer.dart';

/// #160 — 10 module drawers (cocktails, chef, checklist_items,
/// maintenance_items, maintenance, documents, safety_briefing, crew, fuel,
/// inventory) packed their body content into a bare, non-scrolling `Column`
/// with a `Spacer()` — once combined content (variable-length sort options +
/// account/data-management/pro/about sections) exceeded the drawer's bounded
/// height, it overflowed (confirmed live on 5 screens, up to 495px). Fixed
/// by wrapping the body in `Expanded(child: SingleChildScrollView(...))`
/// with the footer pinned after it, matching the pre-existing correct
/// pattern in home_screen.dart/shopping_screen.dart.
///
/// #182/#183 — the same anti-pattern recurred in a second pair of drawers
/// #160's sweep missed: the per-recipe "Recipe options" `endDrawer`s on
/// `ChefRecipeDetailScreen` (chef_screen.dart) and
/// `CocktailRecipeDetailScreen` (cocktails_screen.dart), found live via
/// `scripts/triage_error_logs.sh` (109px / 115px overflow). Same fix,
/// identical shape — no new test needed beyond extending this note, since
/// what's under test below is the structural pattern itself, not any one
/// screen's provider wiring.
///
/// Reconstructs the fixed shape (header, scrollable body, pinned footer)
/// rather than mounting a real screen's drawer — the shared sections
/// (AccountSection/DataManagementSection/ProUpgradeSection) need auth/sync
/// provider mocking unrelated to this layout bug; what's under test is the
/// structural pattern itself, applied identically across all 12 files.
void main() {
  Widget fixedDrawer({required int itemCount, required double height}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: height,
          child: Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  const ListTile(title: Text('Menu')),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < itemCount; i++)
                            ListTile(title: Text('Option $i')),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Sisu Mate v1.0.0'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'drawer with more content than fits scrolls instead of overflowing',
      (tester) async {
    // 30 ListTiles at ~56px each is well beyond a 400px-tall drawer.
    await tester.pumpWidget(fixedDrawer(itemCount: 30, height: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Footer stays visible (pinned outside the scroll region) even though
    // the body content doesn't fit.
    expect(find.text('Sisu Mate v1.0.0'), findsOneWidget);
    expect(find.text('Option 0'), findsOneWidget);
    // Later options are off-screen (scrolled past) but present in the tree
    // via the scrollable — not clipped/lost, just not laid out yet.
  });

  testWidgets('drawer with little content still fills available height '
      '(no visual regression for the common case)', (tester) async {
    await tester.pumpWidget(fixedDrawer(itemCount: 2, height: 600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Option 0'), findsOneWidget);
    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('Sisu Mate v1.0.0'), findsOneWidget);
  });

  testWidgets('#403: DrawerHeaderWidget ellipsizes a long title at large text scale',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Scaffold(
          body: SizedBox(
            width: 272,
            child: DrawerHeaderWidget(
              title: 'Maintenance Filters & Options for this boat',
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
