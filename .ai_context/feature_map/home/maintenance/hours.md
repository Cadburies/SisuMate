title: Engine hours and service log
desc: Recurring tasks by engine hours or months, when each was last done, and what is due next.
layer: ux
keywords: engine hours, service log, due, interval, hour meter, recurring
kind: screen
looks: "Engine Hours & Service Log" screen with a task list, a purple triage button and a + button.
reach: text:Maintenance > tip:Engine Hours & Service Log
needs: -
action: Tap a task to see or log it; + adds a recurring task.
expect: The "Engine Hours & Service Log" screen opens.
uses: shared/record_detail
script: maintenance
source: lib/ui/maintenance/maintenance_hours_screen.dart (MaintenanceHoursScreen)
