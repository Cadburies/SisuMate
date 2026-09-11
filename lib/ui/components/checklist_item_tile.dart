import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../models/models.dart';
import 'smart_image.dart';
import 'sisu_tile_card.dart';
import 'swipeable_list_item.dart';

/// Checklist / Maintenance / Safety tile colour (theme.md §6.5).
/// Grey not-done, green completed, dark grey hidden. Never
/// [ItemListState.unavailable] — red is Chef/Cocktails recipe-missing only.
ItemListState checklistItemListState(ChecklistItem item) => item.isHidden
    ? ItemListState.hidden
    : item.isCompleted
        ? ItemListState.stocked
        : ItemListState.defaults;

/// Shared themed tile for a `ChecklistItem` — used by Checklists, Maintenance,
/// and Safety Briefings so they look and swipe identically (theme.md §6).
/// The tile colour tells the state (green completed / dark hidden / grey
/// default) — no status icon on the tile. Swipe via [SwipeableListItem].
class ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final String groupName;
  final VoidCallback onComplete;
  final VoidCallback onHide;
  final VoidCallback onUnhide;
  final VoidCallback onTap;
  final VoidCallback? onAddToShopping;
  final bool isInShopping;
  final IconData fallbackIcon;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.groupName,
    required this.onComplete,
    required this.onHide,
    required this.onUnhide,
    required this.onTap,
    this.onAddToShopping,
    this.isInShopping = false,
    this.fallbackIcon = Icons.checklist,
  });

  ItemListState get _state => checklistItemListState(item);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = SisuColors.itemStateColors(isDark, _state);

    return SwipeableListItem.checklistItem(
      isCompleted: item.isCompleted,
      isHidden: item.isHidden,
      onComplete: onComplete,
      onHide: onHide,
      onUnhide: onUnhide,
      onAddToShopping: onAddToShopping,
      shoppingIsPending: isInShopping,
      child: SisuTileCard(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        color: c.bg,
        elevation: 3,
        child: ListTile(
          leading: SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SmartImage(
                assetName: item.assetName,
                userPhotoUrl: item.userPhotoUrl,
                userPhotoPath: item.userPhotoPath,
                itemName: item.title,
                groupName: groupName,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                customFallback: Container(
                  color: c.bg.withValues(alpha: 0.5),
                  child: Icon(fallbackIcon, color: c.desc),
                ),
              ),
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(color: c.title, fontWeight: FontWeight.w600),
          ),
          subtitle: item.description != null
              ? Text(item.description!, style: TextStyle(color: c.desc))
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
