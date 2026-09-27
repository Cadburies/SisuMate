title: Log entry parsing (offline first)
desc: Turns free text into logbook fields (time, position, wind, speed, engine hours…) on the device; AI parsing is optional.
layer: ai
keywords: parse, log entry, free text, offline, extract fields
kind: service
looks: -
reach: Captain's Log → AI: Parse freeform entry → Parse offline / Parse
needs: -
action: Rule-based extraction first; the LLM path runs only on "Parse" with a key.
expect: Common phrasings ("12kt SW", "0800") fill the right fields offline.
uses: system/ai/llm_client
script: test/log_entry_local_parse_test.dart
source: lib/services/log_entry_local_parse.dart (LogEntryLocalParse)
