title: Swipe to hide
desc: Swipe a list row to the right and tap Hide to tuck it away without deleting it.
layer: ux
keywords: swipe, hide, remove, declutter, right, soft delete
kind: swipe
looks: Swiping a row right reveals a grey "Hide" button on the left (with "Shopping" where the item can go on the shopping list).
reach: text:Checklists > text:Last Minute Departure Checks > swipe:Final Weather Check:Hide
needs: -
action: Hides the item. Hidden items stay in the list data and can be shown again where the screen offers "Show hidden"; hiding a hidden item deletes it for good.
expect: The row disappears from the list.
uses: -
script: shared_components
source: lib/ui/components/swipeable_list_item.dart (SwipeableListItem, _organiseActions)
