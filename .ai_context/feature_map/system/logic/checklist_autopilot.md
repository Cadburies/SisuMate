title: Checklist autopilot
desc: Suggests which existing checklist to run next from the trip window and weather, by matching checklist titles (last minute, one day, one week, documents, watch).
layer: logic
keywords: autopilot, checklist suggestion, trip, departure
kind: service
looks: -
reach: Checklists screen ("Run before you go" card)
needs: -
action: Keyword-matches existing checklist titles to the trip phase; no new schema.
expect: The right checklist is suggested for the days before departure.
uses: -
script: test/suggestion_engine_test.dart
source: lib/services/suggestion_engine.dart (ChecklistAutopilotSuggestion); lib/providers/checklist_autopilot_provider.dart
