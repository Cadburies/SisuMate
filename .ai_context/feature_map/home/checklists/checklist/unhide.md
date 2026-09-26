title: Unhide an item
desc: Bring a hidden item back into the list.
layer: ux
keywords: unhide, restore, show again, hidden
kind: swipe
looks: With hidden items shown, swiping a hidden row right reveals "Unhide" and "Delete".
reach: text:Checklists > text:Last Minute Departure Checks > swipe:Final Weather Check:Hide > tip:Menu > text:Show Hidden Items > label:Dismiss > swipe:Final Weather Check:Unhide
needs: -
action: Makes the item visible again.
expect: "Final Weather Check" is back in the list as a normal item.
uses: shared/swipe/hide
script: checklists
source: lib/ui/components/swipeable_list_item.dart (_organiseActions); lib/ui/checklists/checklist_items_screen.dart
