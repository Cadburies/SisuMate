title: Boat suggestions
desc: Scans maintenance, stock, documents and weather for things that need attention and turns them into Home suggestions with a link to fix each.
layer: logic
keywords: suggestions, overdue, reminders, alerts, engine
kind: service
looks: -
reach: Home screen build (Suggestions card)
needs: -
action: Ranks findings by severity (urgent / watch / tip) with a route to the module.
expect: Overdue service or low stock shows as a suggestion that opens the right screen.
uses: -
script: test/suggestion_engine_test.dart
source: lib/services/suggestion_engine.dart (SuggestionEngine, BoatSuggestion)
