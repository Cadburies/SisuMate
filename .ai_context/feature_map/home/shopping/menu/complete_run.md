title: Complete the shopping run
desc: Clears everything you marked bought so the list is ready for the next trip; items still to buy stay.
layer: ux
keywords: complete run, clear bought, finish shopping, reset list, next trip
kind: dialog
looks: "Complete shopping run" in the Shopping menu; asks "Complete shopping run?".
reach: text:Shopping > tip:Menu > text:Complete shopping run
needs: -
action: "Clear bought" removes bought items; pantry and bar stock is not changed.
expect: "Complete shopping run?" with Cancel and Clear bought is shown.
uses: -
script: shopping
source: lib/ui/shopping/shopping_screen.dart (ShoppingScreen)
