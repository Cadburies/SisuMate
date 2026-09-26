title: Add shopping item
desc: Adds one custom item to the Shopping list (saved under Misc). Pro only.
layer: ux
keywords: shopping, spares, add, new item, fab, plus
kind: fab
looks: Round "+" button, bottom-right of the Shopping & Spares screen.
reach: text:Shopping > tip:Add item
needs: tier=pro (on Free, tapping + offers the upgrade instead)
action: Opens "Add Shopping Item" where you enter the item name (required), quantity, origin, notes and last price paid.
expect: Tap "Add Item": a message confirms "<name> added to shopping list". With no name you are told "Item name is required".
uses: system/db/shopping_repository, system/pro/paywall
script: shopping
source: lib/ui/shopping/shopping_screen.dart (_showAddItemDialog, _showProRequiredDialog)
