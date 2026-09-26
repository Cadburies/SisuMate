title: New collection
desc: Create a named collection of recipes.
layer: ux
keywords: new collection, create, group, menu
kind: fab
looks: Round + button on Collections; opens "New Collection".
reach: text:Chef > tip:Menu > text:Collections > tip:New collection
needs: -
action: Name it and tap Create, then add recipes to it.
expect: "New Collection" opens.
uses: -
script: chef
source: lib/ui/collections/collections_screen.dart (CollectionsScreen)
