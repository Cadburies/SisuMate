title: Clear all items
desc: Mark every item in a checklist as not done, ready to run it again.
layer: ux
keywords: clear all, reset, untick, start again, bulk
kind: menu
looks: "Clear All" in the checklist's menu.
reach: text:Checklists > text:Last Minute Departure Checks > tip:Menu > text:Clear All
needs: tier=pro
action: Confirm to mark every item not done.
expect: A confirmation to clear all items is shown.
uses: -
script: checklists
source: lib/ui/checklists/checklist_items_screen.dart (ChecklistItemsScreen)
