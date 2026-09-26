title: Add a spare for a task
desc: Create an inventory spare already linked to a maintenance task, with its name filled in. Pro only.
layer: ux
keywords: spare, part, inventory, add spare, stock, linked
kind: button
looks: Small brown box badge on the top-left of each task row.
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:Add spare: Raw Water Pump Service
needs: tier=pro (on Free it explains that spares need Pro)
action: Opens "Add Inventory Item" prefilled with the schedule and task name; scan a barcode or add a photo, then Save.
expect: The "Add Inventory Item" dialog opens with the task name filled in.
uses: home/inventory
script: maintenance
source: lib/ui/maintenance/maintenance_items_screen.dart (_addSpare)
