title: Add a maintenance task
desc: Add your own task to a service schedule. Pro only.
layer: ux
keywords: add, new task, custom, maintenance item
kind: fab
looks: Round + button on a schedule ("Upgrade to Pro" on Free).
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:Add maintenance item
needs: tier=pro (on Free the button reads "Upgrade to Pro")
action: Opens the add-item dialog for this schedule.
expect: The add-item dialog opens.
uses: shared/dialogs/add_checklist_item
script: maintenance
source: lib/ui/maintenance/maintenance_items_screen.dart (MaintenanceItemsScreen)
