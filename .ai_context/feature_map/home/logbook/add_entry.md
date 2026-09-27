title: Add a log entry
desc: Write a new logbook entry: date, notes, weather, wind, position (or use GPS), speed, course, pressure, sea state, engine hours, fuel and crew on watch. Pro only.
layer: ux
keywords: add, new entry, log, write, record, gps, watch
kind: fab
looks: Round + button at the bottom-right of the Captain's Log.
reach: text:Captain's Log > tip:Add log entry
needs: tier=pro (on Free it explains that editing needs Pro)
action: Opens "New Log Entry"; Save adds it to the log.
expect: "New Log Entry" opens; after Save the entry shows in the list and "Log entry added" appears.
uses: -
script: logbook
source: lib/ui/logbook/logbook_screen.dart (_showAddEditDialog); lib/ui/logbook/logbook_screen.dart (AddEditCaptainLogDialog)
