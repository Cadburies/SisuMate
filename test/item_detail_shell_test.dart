import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/ui/components/item_detail_shell.dart';

void main() {
  // TitleTile (inside the shell) watches syncOutboxCountProvider; stub it so
  // widget tests never touch Drift (real async I/O deadlocks the fake clock).
  final noOutbox = syncOutboxCountProvider.overrideWith(
    (ref) => Stream<int>.value(0),
  );

  testWidgets('ItemDetailShell shows title, sticky action, and history',
      (tester) async {
    final titles = ['Alpha', 'Bravo', 'Charlie'];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noOutbox],
        child: MaterialApp(
          home: ItemDetailShell(
            itemCount: titles.length,
            initialIndex: 0,
            titleForIndex: (i) => titles[i],
            contentBuilder: (context, index, isEditing) =>
                Text(isEditing ? 'Editing ${titles[index]}' : titles[index]),
            historyForIndex: (i) => ['Created $i', 'Updated $i'],
            actionsForIndex:
                (context, index, isEditing, startEdit, cancelEdit, saveEdit) =>
                    [
              DetailAction(
                icon: Icons.edit,
                label: 'Edit',
                onPressed: startEdit,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Created 0'), findsOneWidget);
    // Swipe to next item
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Bravo'), findsWidgets);
  });

  testWidgets('ItemDetailShell edit locks paging and Save/Cancel appear',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noOutbox],
        child: MaterialApp(
          home: ItemDetailShell(
            itemCount: 2,
            initialIndex: 0,
            titleForIndex: (i) => 'Item $i',
            contentBuilder: (context, index, isEditing) =>
                Text(isEditing ? 'EDIT MODE' : 'VIEW MODE'),
            onSaveEdit: (_) async {},
            actionsForIndex:
                (context, index, isEditing, startEdit, cancelEdit, saveEdit) {
              if (isEditing) {
                return [
                  DetailAction(
                      icon: Icons.close,
                      label: 'Cancel',
                      onPressed: cancelEdit),
                  DetailAction(
                      icon: Icons.save,
                      label: 'Save',
                      onPressed: () => saveEdit()),
                ];
              }
              return [
                DetailAction(
                    icon: Icons.edit, label: 'Edit', onPressed: startEdit),
              ];
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('VIEW MODE'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('EDIT MODE'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
