title: Passage debrief
desc: Summarises a completed passage: distance, time, average speed, fuel used.
layer: logic
keywords: debrief, passage stats, summary, fuel used
kind: service
looks: -
reach: after a passage (log and fuel data)
needs: -
action: Aggregates log entries and fuel fills for the passage.
expect: Stats for the passage are shown.
uses: system/logic/fuel_burn_estimate
script: test/passage_debrief_service_test.dart
source: lib/services/passage_debrief_service.dart (PassageDebriefService, PassageDebriefStats)
