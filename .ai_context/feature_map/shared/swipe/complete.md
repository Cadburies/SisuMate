title: Swipe to complete
desc: Swipe a list row to the left to mark it done, or undo it; the row turns green.
layer: ux
keywords: swipe, complete, done, tick, finish, uncomplete, left, mark
kind: swipe
looks: Swiping a row left reveals a green "Complete" button on the right ("Uncomplete" once done).
reach: text:Checklists > text:Last Minute Departure Checks > swipe:Final Weather Check:Complete
needs: tier=pro (on Free a banner says "Marking items complete requires Sisu Pro" with an Upgrade button)
action: Toggles the item between done and not done.
expect: The row is marked done; swiping it again offers "Uncomplete".
uses: -
script: shared_components
source: lib/ui/components/swipeable_list_item.dart (SwipeableListItem, _stateActions); lib/ui/components/checklist_item_tile.dart (ChecklistItemTile)
