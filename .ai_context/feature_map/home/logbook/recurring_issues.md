title: Find recurring issues
desc: Scans your log and maintenance notes for problems that keep coming back. Works offline; AI can add a write-up.
layer: ux
keywords: recurring, patterns, repeat problems, history, issues, ai
kind: dialog
looks: Purple sparkle button in the Captain's Log title bar; opens "Recurring Issues".
reach: text:Captain's Log > tip:AI: Find recurring issues
needs: -
action: Lists repeating problems found on the device; "Narrate with AI" adds a summary when online with a key. Needs a few notes first.
expect: With too few notes it says there is not enough history yet.
uses: system/ai/history_pattern
script: logbook
source: lib/ui/logbook/history_pattern_dialog.dart; lib/services/history_pattern_local.dart
