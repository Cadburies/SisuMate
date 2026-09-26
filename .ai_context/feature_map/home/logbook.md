title: Captain's Log
desc: Your boat's logbook: dated entries with notes, weather, wind, position, speed, engine hours and fuel.
layer: ux
keywords: logbook, log, captain's log, journal, entries, passage log
kind: screen
looks: "Captain's Log" list of entries by date, a purple AI button and a + button bottom-right.
reach: text:Captain's Log
needs: -
action: Tap an entry to read it; + adds one; the purple buttons parse free text or find recurring issues.
expect: "No log entries" on a fresh install.
uses: -
script: logbook
source: lib/ui/logbook/logbook_screen.dart (LogbookScreen)
