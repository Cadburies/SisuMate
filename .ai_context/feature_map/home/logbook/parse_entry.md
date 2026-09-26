title: Turn free text into a log entry
desc: Type or paste a sentence like "motored out past the point around 0800, 12kt SW" and have it split into log fields. Works offline; AI optional. Pro only.
layer: ux
keywords: parse, free text, dictate, quick entry, ai, offline, convert
kind: dialog
looks: Purple sparkle button next to +; opens "AI: Parse Log Entry" with Parse offline and Parse.
reach: text:Captain's Log > tip:AI: Parse freeform entry
needs: tier=pro
action: "Parse offline" fills the fields on the device; "Parse" uses your AI provider when online with a key. You check the result before saving.
expect: "AI: Parse Log Entry" with "Parse offline" is shown.
uses: system/ai/log_entry_parse
script: logbook
source: lib/ui/logbook/ai_log_entry_parse_dialog.dart; lib/services/log_entry_local_parse.dart
