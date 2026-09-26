title: Read a log entry
desc: Shows one log entry in full, with Edit and Delete.
layer: ux
keywords: entry, read, view, detail, edit, delete
kind: dialog
looks: "Log Entry - <date>" dialog with the notes and other fields, and Delete, Edit, Close buttons.
reach: text:Captain's Log > tip:Add log entry > type:Notes=Raw water pump leaking > text:Save > text:Raw water pump leaking
needs: tier=pro
action: Edit reopens the entry form; Delete removes it.
expect: "Log Entry - <date>" with the notes is shown.
uses: -
script: logbook
source: lib/ui/logbook/logbook_screen.dart (LogbookScreen)
