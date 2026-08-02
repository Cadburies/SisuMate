import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// #206: `ItemDetailShell` (`lib/ui/components/item_detail_shell.dart`,
/// around line 244) lays out a fixed-height image box followed by a content
/// box whose `minHeight` is `constraints.maxHeight - imageHeight`. On a
/// screen shorter than the fixed 200px image (or any frame where the
/// available height is transiently smaller than that — a page transition, a
/// small physical device), that subtraction goes negative, which
/// `BoxConstraints` forbids ("has a negative minimum height").
///
/// This test isolates the exact vulnerable shape (a `LayoutBuilder` feeding
/// `constraints.maxHeight - fixedHeight` into a child `BoxConstraints`)
/// rather than pumping the full `ItemDetailShell` widget — that widget's
/// Riverpod/Drift/TitleTile dependencies made a hermetic widget test
/// unreliable (unrelated pending-timer/overflow noise from squeezing a real
/// Scaffold into an unrealistically short viewport), independent of whether
/// this specific bug is present. Keep this constant list in sync with the
/// real fix if either changes.
void main() {
  Widget buildAt(double availableHeight, {required bool clamped}) {
    const fixedImageHeight = 200.0;
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: availableHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rawMinHeight = constraints.maxHeight - fixedImageHeight;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: clamped
                      ? rawMinHeight.clamp(0.0, double.infinity)
                      : rawMinHeight,
                ),
                child: const SizedBox(),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets(
      'unclamped: a short available height throws the negative-minimum-'
      'height assertion (proves this test would have caught #206)',
      (tester) async {
    await tester.pumpWidget(buildAt(80, clamped: false));
    await tester.pump();

    final exception = tester.takeException();
    expect(exception, isNotNull);
    expect(exception.toString(), contains('negative minimum height'));
  });

  testWidgets(
      'clamped (the #206 fix): the same short available height does not throw',
      (tester) async {
    await tester.pumpWidget(buildAt(80, clamped: true));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
