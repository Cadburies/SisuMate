import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/ui/components/title_tile.dart';

/// #269 — no RenderFlex overflow on narrow widths.
/// #279 — menu stays far-right; title keeps usable width (not crushed by
/// Flexible trailing).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpTile(
    WidgetTester tester, {
    required double width,
    required Widget body,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(home: Scaffold(body: body)),
      ),
    );
    await tester.pump();
  }

  testWidgets(
      '#269 — narrow width with back + multiple trailing actions does not '
      'overflow the header Row', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      oldHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldHandler);

    await pumpTile(
      tester,
      width: 320,
      body: Column(
        children: [
          TitleTile(
            title: 'Anchor Alarm',
            onMenuPressed: () {},
            actionsBuilder: (color) => [
              IconButton(
                icon: Icon(Icons.ios_share, color: color),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.upload_file, color: color),
                onPressed: () {},
              ),
            ],
          ),
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: TitleTile(
                        title: 'Nested Screen With Long Title',
                        onMenuPressed: () {},
                        actionsBuilder: (color) => [
                          IconButton(
                            icon: Icon(Icons.share, color: color),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.ios_share, color: color),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open nested'),
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.text('open nested'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final overflows = errors.where(
      (e) => e.exceptionAsString().contains('overflowed'),
    );
    expect(overflows, isEmpty,
        reason: errors.map((e) => e.exceptionAsString()).join('\n'));
    expect(find.byType(TitleTile), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
      '#279 — menu is rightmost trailing control; title keeps usable width',
      (tester) async {
    await pumpTile(
      tester,
      width: 360,
      body: TitleTile(
        title: 'Boat Polar Data Settings',
        onMenuPressed: () {},
        actionsBuilder: (color) => [
          IconButton(
            key: const ValueKey('action_share'),
            icon: Icon(Icons.share, color: color),
            onPressed: () {},
          ),
          IconButton(
            key: const ValueKey('action_export'),
            icon: Icon(Icons.upload_file, color: color),
            onPressed: () {},
          ),
        ],
      ),
    );

    final menu = tester.getRect(find.byKey(const ValueKey('title_tile_menu')));
    final share = tester.getRect(find.byKey(const ValueKey('action_share')));
    final export = tester.getRect(find.byKey(const ValueKey('action_export')));
    final titleText = tester.getRect(find.text('Boat Polar Data Settings'));

    // Menu is the rightmost of the three trailing controls.
    expect(menu.right, greaterThanOrEqualTo(export.right));
    expect(menu.right, greaterThanOrEqualTo(share.right));
    // Actions pack to the left of the menu.
    expect(export.right, lessThanOrEqualTo(menu.left + 1));
    expect(share.right, lessThanOrEqualTo(export.left + 1));

    // Title is not crushed to a sliver (Flexible trailing regression).
    expect(titleText.width, greaterThan(80));

    // Menu sits near the right edge of a 360-wide surface.
    expect(menu.right, greaterThan(360 - 48));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}
