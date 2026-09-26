title: Swipe to mark in stock
desc: Swipe a pantry or bar ingredient to the left and tap In stock to record that it is aboard.
layer: ux
keywords: swipe, in stock, aboard, have, pantry, bar, ingredient, remove
kind: swipe
looks: Swiping an ingredient row left reveals a green "In stock" button ("Remove" once it is aboard).
reach: text:Chef > text:My Pantry > swipe:Aged Balsamic Vinegar:In stock
needs: -
action: Marks the ingredient as aboard, which updates which recipes you can make.
expect: The ingredient turns green; swiping it again offers "Remove".
uses: -
script: shared_components
source: lib/ui/components/swipeable_list_item.dart (SwipeableListItem.ingredientItem, _stateActions)
