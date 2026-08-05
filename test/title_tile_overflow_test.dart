import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/ui/components/title_tile.dart';

/// #269 — TitleTile Row overflowed by 16px on a real iPhone (320×50
/// constraints) when back + status text + trailing actions competed for
/// width without the trailing group being allowed to flex/scroll.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

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

    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: Scaffold(
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
                // Nested route so canPop is true (back button present).
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
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('open nested'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final overflows = errors.where(
      (e) => e.exceptionAsString().contains('overflowed'),
    );
    expect(overflows, isEmpty, reason: errors.map((e) => e.exceptionAsString()).join('\n'));
    expect(find.byType(TitleTile), findsWidgets);

    // Flush Drift StreamQueryStore cancel timers on unmount (#268 pattern).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}
