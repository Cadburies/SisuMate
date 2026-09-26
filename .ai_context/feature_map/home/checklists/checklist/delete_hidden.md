title: Delete a hidden item
desc: Permanently delete an item you had hidden.
layer: ux
keywords: delete, remove for good, permanent, hidden
kind: swipe
looks: With hidden items shown, swiping a hidden row right reveals "Delete".
reach: text:Checklists > text:Last Minute Departure Checks > swipe:Final Weather Check:Hide > tip:Menu > text:Show Hidden Items > label:Dismiss > swipe:Final Weather Check:Delete
needs: -
action: Deletes the item permanently.
expect: "Final Weather Check" is gone even with hidden items shown.
uses: shared/swipe/hide
script: checklists
source: lib/ui/components/swipeable_list_item.dart (_organiseActions); lib/ui/checklists/checklist_items_screen.dart
