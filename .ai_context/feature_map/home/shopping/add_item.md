title: Add shopping item
desc: Adds one custom item to the Shopping list (saved under Misc). Pro only.
layer: ux
keywords: shopping, spares, add, new item, fab, plus
kind: fab
looks: Round "+" button, bottom-right of the Shopping & Spares screen.
reach: text:Shopping > tip:Add item
needs: tier=pro (Free → "Sisu Mate Pro Required" dialog → Upgrade opens paywall)
action: Opens dialog "Add Shopping Item": Item Name*, Quantity, Origin, Notes, Last Purchase Price.
expect: "Add Item" saves → snackbar "<name> added to shopping list". Empty name → "Item name is required".
uses: system/db/shopping_repository, system/pro/paywall
script: shopping
source: lib/ui/shopping/shopping_screen.dart (_showAddItemDialog, _showProRequiredDialog)
