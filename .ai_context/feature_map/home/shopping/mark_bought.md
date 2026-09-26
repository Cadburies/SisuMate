title: Mark an item bought
desc: Swipe a shopping item left to mark it bought; it drops out of "to buy".
layer: ux
keywords: bought, purchased, got it, done, swipe, tick
kind: swipe
looks: Swiping an item row left reveals "Complete".
reach: text:Shopping > tip:Add item > type:Item Name=Impeller > text:Add Item > text:Spares > swipe:Impeller:Complete
needs: tier=pro
action: Marks the item bought; the trip estimate updates.
expect: "Trip estimate (to buy)" shows "Nothing pending".
uses: shared/swipe/complete
script: shopping
source: lib/ui/shopping/shopping_screen.dart (ShoppingScreen)
