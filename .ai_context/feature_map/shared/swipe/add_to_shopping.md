title: Swipe to add to shopping
desc: Swipe a pantry or bar ingredient to the right and tap Shopping to put it on the shopping list.
layer: ux
keywords: swipe, shopping, buy, add to list, pantry, bar, ingredient
kind: swipe
looks: Swiping an ingredient row right reveals a blue "Shopping" button ("Done" once it is on the list).
reach: text:Chef > text:My Pantry > swipe:Aged Balsamic Vinegar:Shopping
needs: -
action: Adds the ingredient to the Shopping list; swiping again and tapping Done takes it off.
expect: The row shows "On shopping list".
uses: home/shopping
script: shared_components
source: lib/ui/components/swipeable_list_item.dart (SwipeableListItem.ingredientItem)
