title: Item shop guide
desc: Offline advice on where to buy one item and any customs flags, without needing a connection.
layer: ux
keywords: shop guide, where to buy, chandlery, store, customs, offline
kind: button
looks: Small purple sparkle badge on each item row.
reach: text:Shopping > tip:Add item > type:Item Name=Impeller > text:Add Item > text:Spares > tip:Shop guide: Impeller
needs: tier=pro
action: Opens "Shop: <item>" with the kinds of shop to try and a compliance reminder; "Plan port run for this list" jumps to the port run.
expect: "Shop: Impeller" with an offline shopping guide is shown.
uses: system/logic/shopping_local_guide
script: shopping
source: lib/ui/shopping/shopping_item_ai_dialog.dart (ShoppingItemAiDialog); lib/services/shopping_item_local_guide.dart
