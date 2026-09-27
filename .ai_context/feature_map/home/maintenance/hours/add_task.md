title: Add a recurring maintenance task
desc: Add a task that repeats every so many engine hours or months. Pro only.
layer: ux
keywords: add, recurring, interval, engine hours, months, task
kind: fab
looks: Round + button on the Engine Hours & Service Log ("Upgrade to Pro" on Free).
reach: text:Maintenance > tip:Engine Hours & Service Log > tip:Add maintenance task
needs: tier=pro (on Free the button reads "Upgrade to Pro")
action: Opens "Add Maintenance Task": description, interval in engine hours and/or months, last done date and hours.
expect: The "Add Maintenance Task" dialog opens; Save adds the task with "Never logged done".
uses: -
script: maintenance
source: lib/ui/maintenance/maintenance_hours_screen.dart (MaintenanceHoursScreen); lib/ui/maintenance/maintenance_hours_screen.dart (AddEditMaintenanceTaskDialog)
