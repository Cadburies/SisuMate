title: Complete all items
desc: Mark every item in a checklist as done in one go, after confirming.
layer: ux
keywords: complete all, tick all, done, finish list, bulk
kind: menu
looks: "Complete All" in the checklist's menu; asks "Complete All Items?".
reach: text:Checklists > text:Last Minute Departure Checks > tip:Menu > text:Complete All
needs: tier=pro
action: Confirm to mark every item done.
expect: "Complete All Items?" with Cancel and Complete All is shown.
uses: -
script: checklists
source: lib/ui/checklists/checklist_items_screen.dart (ChecklistItemsScreen)
