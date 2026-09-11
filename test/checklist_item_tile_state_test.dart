import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/colors.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/components/checklist_item_tile.dart';
import 'package:sisu_mate/ui/components/sisu_tile_card.dart';

/// #346: Safety / Maintenance / Checklists tiles are grey / green / dark grey.
/// Red (`ItemListState.unavailable`) is Chef/Cocktails recipe-missing only.
/// Deleted is permanent — the row leaves the list; never a red tile.

ChecklistItem _item({
  bool isCompleted = false,
  bool isHidden = false,
  bool isPermanentlyDeleted = false,
}) {
  return ChecklistItem()
    ..supabaseId = 'i1'
    ..title = 'Check bilge'
    ..name = 'Check bilge'
    ..isCompleted = isCompleted
    ..isHidden = isHidden
    ..isPermanentlyDeleted = isPermanentlyDeleted;
}

Widget _app(ChecklistItem item, {required Brightness brightness}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(
      body: ChecklistItemTile(
        item: item,
        groupName: 'Safety',
        onComplete: () {},
        onHide: () {},
        onUnhide: () {},
        onTap: () {},
      ),
    ),
  );
}

void main() {
  group('checklistItemListState', () {
    test('not-done is defaults (grey), never unavailable', () {
      expect(checklistItemListState(_item()), ItemListState.defaults);
    });

    test('completed is stocked (green), never unavailable', () {
      expect(
        checklistItemListState(_item(isCompleted: true)),
        ItemListState.stocked,
      );
    });

    test('hidden is hidden (dark grey), even if completed', () {
      expect(
        checklistItemListState(_item(isHidden: true, isCompleted: true)),
        ItemListState.hidden,
      );
    });

    test(
      'permanentlyDeleted still is not red (row should already be gone)',
      () {
        expect(
          checklistItemListState(_item(isPermanentlyDeleted: true)),
          isNot(ItemListState.unavailable),
        );
        expect(
          checklistItemListState(
            _item(isPermanentlyDeleted: true, isHidden: true),
          ),
          ItemListState.hidden,
        );
      },
    );
  });

  group('ChecklistItemTile colour', () {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      final isDark = brightness == Brightness.dark;
      final red = SisuColors.itemStateColors(isDark, ItemListState.unavailable);

      testWidgets(
        '$brightness not-done / completed / hidden / pre-delete tiles '
        'are never red',
        (tester) async {
          final cases = <(ChecklistItem, ItemListState)>[
            (_item(), ItemListState.defaults),
            (_item(isCompleted: true), ItemListState.stocked),
            (_item(isHidden: true), ItemListState.hidden),
            (_item(isPermanentlyDeleted: true), ItemListState.defaults),
          ];

          for (final (item, expected) in cases) {
            await tester.pumpWidget(_app(item, brightness: brightness));
            final card = tester.widget<SisuTileCard>(find.byType(SisuTileCard));
            final want = SisuColors.itemStateColors(isDark, expected);
            expect(card.color, want.bg);
            expect(card.color, isNot(red.bg));
            expect(expected, isNot(ItemListState.unavailable));
          }
        },
      );
    }
  });
}
