import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/colors.dart';

/// Universal swipeable list item (theme.md §6.6). Uniform across every list:
///   Swipe RIGHT (icons appear on the LEFT)  = organise: (un)hide, delete-when-
///                                             hidden (red), shopping (blue),
///                                             email (indigo).
///   Swipe LEFT  (icons appear on the RIGHT) = state toggle only: (un)complete
///                                             / in-stock — no secondary actions.
/// Complete and stock are **toggles** — always available; the label/colour
/// flips with `isCompleted` / `isStocked`.
class SwipeableListItem extends StatelessWidget {
  final Widget child;
  final bool isHidden;
  final bool isCompleted;
  final bool isStocked;
  final VoidCallback? onComplete; // toggles complete (always allowed)
  final VoidCallback? onHide; // hide when visible; permanent-delete when hidden
  final VoidCallback? onUnhide;
  final VoidCallback? onAddToShopping;
  /// When true, the shopping swipe action becomes green **Done** (mark bought).
  final bool shoppingIsPending;
  final VoidCallback? onToggleStock; // toggles in-bar / in-pantry
  final VoidCallback? onEmail;
  /// Permanent delete for items that skip the hide workflow (e.g. custom bar
  /// ingredients). Shown on the organise (swipe-right) pane as red Delete.
  final VoidCallback? onDelete;

  const SwipeableListItem({
    super.key,
    required this.child,
    required this.isHidden,
    this.isCompleted = false,
    this.isStocked = false,
    this.onComplete,
    this.onHide,
    this.onUnhide,
    this.onAddToShopping,
    this.shoppingIsPending = false,
    this.onToggleStock,
    this.onEmail,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      // Swipe RIGHT → icons on the LEFT: (un)hide, shopping, email, delete
      startActionPane: _pane(_organiseActions()),
      // Swipe LEFT  → icons on the RIGHT: complete / stock only
      endActionPane: _pane(_stateActions()),
      child: child,
    );
  }

  ActionPane? _pane(List<SlidableAction> actions) {
    if (actions.isEmpty) return null;
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: (actions.length * 0.25).clamp(0.25, 0.75),
      children: actions,
    );
  }

  List<SlidableAction> _organiseActions() {
    final actions = <SlidableAction>[];
    if (isHidden) {
      if (onUnhide != null) {
        actions.add(SlidableAction(
          onPressed: (_) => onUnhide!(),
          backgroundColor: SisuColors.hideAction,
          foregroundColor: Colors.white,
          icon: Icons.undo,
          label: 'Unhide',
        ));
      }
      // When hidden, `onHide` performs the permanent (soft→hard) delete.
      if (onHide != null) {
        actions.add(SlidableAction(
          onPressed: (_) => onHide!(),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          icon: Icons.delete_forever,
          label: 'Delete',
        ));
      }
    } else if (onHide != null) {
      actions.add(SlidableAction(
        onPressed: (_) => onHide!(),
        backgroundColor: SisuColors.hideAction,
        foregroundColor: Colors.white,
        icon: Icons.visibility_off,
        label: 'Hide',
      ));
    }
    if (onAddToShopping != null) {
      actions.add(SlidableAction(
        onPressed: (_) => onAddToShopping!(),
        // Blue = add to cart; green Done = mark that cart line bought.
        backgroundColor: shoppingIsPending
            ? SisuColors.completedBackground
            : Colors.blue,
        foregroundColor: Colors.white,
        icon: shoppingIsPending ? Icons.done : Icons.add_shopping_cart,
        label: shoppingIsPending ? 'Done' : 'Shopping',
      ));
    }
    // Email sits with organise actions (next to hide), not with Complete.
    if (onEmail != null) {
      actions.add(SlidableAction(
        onPressed: (_) => onEmail!(),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: Icons.email_outlined,
        label: 'Email',
      ));
    }
    if (!isHidden && onDelete != null) {
      actions.add(SlidableAction(
        onPressed: (_) => onDelete!(),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: Icons.delete,
        label: 'Delete',
      ));
    }
    return actions;
  }

  List<SlidableAction> _stateActions() {
    final actions = <SlidableAction>[];
    if (onComplete != null) {
      actions.add(SlidableAction(
        onPressed: (_) => onComplete!(),
        backgroundColor: isCompleted
            ? SisuColors.incompleteBackground
            : SisuColors.completedBackground,
        foregroundColor: Colors.white,
        icon: isCompleted ? Icons.remove_done : Icons.check,
        label: isCompleted ? 'Uncomplete' : 'Complete',
      ));
    }
    if (onToggleStock != null) {
      actions.add(SlidableAction(
        onPressed: (_) => onToggleStock!(),
        backgroundColor: isStocked
            ? SisuColors.incompleteBackground
            : SisuColors.completedBackground,
        foregroundColor: Colors.white,
        icon: isStocked ? Icons.remove_circle_outline : Icons.check,
        label: isStocked ? 'Remove' : 'In stock',
      ));
    }
    return actions;
  }

  /// Factory for checklist items. Complete is a toggle; hide flips to
  /// unhide + delete once hidden.
  factory SwipeableListItem.checklistItem({
    required bool isCompleted,
    required bool isHidden,
    required VoidCallback onComplete,
    required VoidCallback onHide,
    VoidCallback? onUnhide,
    VoidCallback? onAddToShopping,
    bool shoppingIsPending = false,
    required Widget child,
  }) {
    return SwipeableListItem(
      isHidden: isHidden,
      isCompleted: isCompleted,
      onComplete: onComplete,
      onHide: onHide,
      onUnhide: onUnhide,
      onAddToShopping: onAddToShopping,
      shoppingIsPending: shoppingIsPending,
      child: child,
    );
  }

  /// Factory for shopping items.
  factory SwipeableListItem.shoppingItem({
    required bool isBought,
    required bool isHidden,
    required VoidCallback onMarkBought,
    required VoidCallback onHide,
    required VoidCallback? onAddToShopping,
    required VoidCallback? onToggleStock,
    VoidCallback? onEmail,
    required Widget child,
  }) {
    return SwipeableListItem(
      isHidden: isHidden,
      isCompleted: isBought,
      onComplete: onMarkBought,
      onHide: onHide,
      onAddToShopping: onAddToShopping,
      onToggleStock: onToggleStock,
      onEmail: onEmail,
      child: child,
    );
  }

  /// Factory for inventory items.
  factory SwipeableListItem.inventoryItem({
    required bool isHidden,
    required VoidCallback onHide,
    VoidCallback? onUnhide,
    required Widget child,
  }) {
    return SwipeableListItem(
      isHidden: isHidden,
      onHide: onHide,
      onUnhide: onUnhide,
      child: child,
    );
  }

  /// Factory for ingredient tiles (bar / pantry).
  /// Swipe RIGHT → Shopping / Done when already on list (+ Delete for custom).
  /// Swipe LEFT → in-stock toggle.
  factory SwipeableListItem.ingredientItem({
    required bool isActive,
    required bool isCustom,
    required bool isInShopping,
    required VoidCallback onToggleStatus,
    required VoidCallback onAddToShopping,
    required VoidCallback onMarkShoppingDone,
    VoidCallback? onDelete,
    required Widget child,
  }) {
    return SwipeableListItem(
      isHidden: false,
      isStocked: isActive,
      onToggleStock: onToggleStatus,
      shoppingIsPending: isInShopping,
      onAddToShopping: isInShopping ? onMarkShoppingDone : onAddToShopping,
      onDelete: isCustom ? onDelete : null,
      child: child,
    );
  }
}
