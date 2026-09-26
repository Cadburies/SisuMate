title: Sort the shopping list
desc: Choose how the shopping list is ordered: original, name, what is needed first, or price.
layer: ux
keywords: sort, order, name, priority, price, needed first
kind: chip
looks: Row of chips under the title bar: Original, Name A-Z, Needed First, Price Low-High.
reach: text:Shopping > text:Name A-Z
needs: -
action: Re-orders every category by the chosen chip.
expect: The list is re-ordered by name.
uses: -
script: shopping
source: lib/ui/shopping/shopping_screen.dart (ShoppingScreen)
