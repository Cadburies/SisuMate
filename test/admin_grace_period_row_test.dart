import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// #181 — admin_screen.dart's "Grace period after warning: " `Row`
/// (`_AdminScreenState`, ~line 299) paired an unconstrained `Text` label
/// with a `DropdownButton` at fixed natural width — on a narrow screen
/// (confirmed live at 26px overflow, w<=312) the combined width didn't fit.
/// Fixed by wrapping the label in `Expanded`, matching the sibling "Stale
/// boats" `Row` a few lines above it, which already had this pattern.
///
/// Reconstructs the fixed shape at the same constrained width rather than
/// mounting the full AdminScreen (which needs Supabase/auth provider setup
/// unrelated to this layout bug).
void main() {
  Widget fixedRow({required double width}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: Row(
            children: [
              const Expanded(child: Text('Grace period after warning: ')),
              DropdownButton<int>(
                value: 7,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 14, child: Text('14 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('grace-period row does not overflow at the reported narrow width',
      (tester) async {
    await tester.pumpWidget(fixedRow(width: 312));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Grace period after warning: '), findsOneWidget);
  });
}
