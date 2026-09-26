title: Buy before passage
desc: A banner listing the boat-critical items still to buy before you sail, with a shortcut to sort by priority.
layer: ux
keywords: buy before passage, critical, priority, spares, before sailing
kind: card
looks: Tinted card at the top of Shopping titled "Buy before passage" with a "Sort by priority" button.
reach: text:Shopping > tip:Add item > type:Item Name=Impeller > text:Add Item
needs: tier=pro
action: Lists pending boat-critical items; "Sort by priority" switches the list to priority order.
expect: "Buy before passage" shows "Impeller — Boat-critical (spares)".
uses: -
script: shopping
source: lib/ui/shopping/shopping_screen.dart (ShoppingScreen)
