title: Add a checklist item
desc: Add your own step to a checklist. Pro only.
layer: ux
keywords: add, new item, step, checklist, custom
kind: dialog
looks: Round + button on a checklist's item list ("Upgrade to Pro" on Free).
reach: text:Checklists > text:Last Minute Departure Checks > tip:Add checklist item
needs: tier=pro (on Free the same button reads "Upgrade to Pro")
action: Opens the "Add checklist item" dialog.
expect: The "Add checklist item" dialog with Cancel and Add is shown.
uses: -
script: shared_components
source: lib/ui/components/add_checklist_item_dialog.dart
