title: Shopping item page
desc: Full page for one shopping item: quantity, price, status, origin and when it was last changed.
layer: ux
keywords: item, detail, quantity, price, bought, status
kind: screen
looks: Item name, "<category> · N of M", quantity, price, status, with Bought, Hide and Edit buttons.
reach: text:Shopping > tip:Add item > type:Item Name=Impeller > text:Add Item > text:Spares > text:Impeller
needs: tier=pro
action: Mark it bought, hide it or edit it; swipe sideways for the next item.
expect: "Status: to buy" and a "Bought" button are shown.
uses: shared/check_page_viewer/edit
script: shopping
source: lib/ui/shopping/shopping_screen.dart (ShoppingScreen); lib/ui/components/item_detail_shell.dart (ItemDetailShell); lib/ui/shopping/shopping_screen.dart (ShoppingItemDetailScreen)
