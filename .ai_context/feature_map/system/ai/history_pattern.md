title: Recurring-issue detection (offline first)
desc: Finds problems that keep recurring across log and maintenance notes by local co-occurrence scanning; AI narration is optional.
layer: ai
keywords: recurring, patterns, history, issues, offline
kind: service
looks: -
reach: Captain's Log → AI: Find recurring issues
needs: -
action: Needs a minimum number of notes; reports repeating keywords with dates.
expect: Too little history gives a "not enough notes yet" message.
uses: system/ai/llm_client
script: test/history_pattern_local_test.dart
source: lib/services/history_pattern_local.dart (HistoryPatternLocal)
