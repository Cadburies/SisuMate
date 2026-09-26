title: Show hidden items
desc: Show items you hid, so you can unhide them or delete them for good.
layer: ux
keywords: hidden, show hidden, unhide, restore, deleted items
kind: toggle
looks: "Show Hidden Items / Display soft-deleted items" switch in the checklist's menu.
reach: text:Checklists > text:Last Minute Departure Checks > tip:Menu > text:Show Hidden Items
needs: -
action: Turns hidden items back on in the list, shown in dark grey.
expect: Hidden items appear in the list after the menu is closed.
uses: -
script: checklists
source: lib/ui/checklists/checklist_items_screen.dart (ChecklistItemsScreen)
