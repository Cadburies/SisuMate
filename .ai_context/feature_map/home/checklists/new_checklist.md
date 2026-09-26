title: New checklist
desc: Create your own empty checklist and add items to it. Pro only.
layer: ux
keywords: new, create, custom, own checklist, add list
kind: fab
looks: Round + button on the Checklists screen ("Upgrade to Pro" on Free).
reach: text:Checklists > tip:Create custom checklist
needs: tier=pro (on Free the button reads "Upgrade to Pro")
action: Opens "New Checklist"; enter a name and tap Create.
expect: The "New Checklist" dialog opens; after Create the new checklist appears in the list.
uses: shared/dialogs/add_checklist_item
script: checklists
source: lib/ui/checklists/checklist_screen.dart (ChecklistScreen)
