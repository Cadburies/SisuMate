title: Recipe collections
desc: Group recipes and drinks into themed lists such as "Boat Party Menu".
layer: ux
keywords: collections, groups, themed menu, party, list of recipes
kind: screen
looks: "Collections" list, opened from the Chef menu; + creates one.
reach: text:Chef > tip:Menu > text:Collections
needs: -
action: Tap a collection to see and add its recipes.
expect: "No collections yet" on a fresh install.
uses: -
script: chef
source: lib/ui/collections/collections_screen.dart (CollectionsScreen)
