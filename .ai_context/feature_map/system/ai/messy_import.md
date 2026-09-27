title: Messy list import (offline first)
desc: Turns pasted text or CSV into module items on the device; AI mapping is optional.
layer: ai
keywords: messy import, paste, csv, parse, offline
kind: service
looks: -
reach: import/export sheet → Paste messy list → Parse
needs: -
action: Heuristic line/column parsing first; the LLM path enriches when online with a key.
expect: A pasted list becomes items with quantities where given.
uses: system/ai/llm_client
script: test/messy_import_local_parse_test.dart
source: lib/services/messy_import_local_parse.dart (MessyImportLocalParse)
