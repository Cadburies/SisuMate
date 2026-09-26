title: A checklist's items
desc: The items in one checklist, coloured by state, with swipe actions and a + to add your own.
layer: ux
keywords: checklist, items, steps, tick, progress
kind: screen
looks: Checklist title bar, then a list of item rows with their descriptions; + button bottom-right.
reach: text:Checklists > text:Last Minute Departure Checks
needs: -
action: Tap an item for its full page, swipe left to complete, swipe right to hide.
expect: Items such as "Final Weather Check" are listed.
uses: shared/swipe/complete, shared/swipe/hide, shared/check_page_viewer, shared/dialogs/add_checklist_item, shared/import_export
script: checklists
source: lib/ui/checklists/checklist_items_screen.dart (ChecklistItemsScreen)
