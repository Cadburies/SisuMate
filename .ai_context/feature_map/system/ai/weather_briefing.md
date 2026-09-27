title: Passage weather briefing
desc: Summarises weather risks along a planned passage from the cached forecast.
layer: ai
keywords: weather briefing, passage, risk, summary
kind: service
looks: -
reach: Passage Planner → AI: Weather safety briefing
needs: -
action: Needs a cached forecast for the area; otherwise it asks you to load one first.
expect: With cached weather, a briefing appears; without, a clear prompt to load a forecast.
uses: system/network/offline_weather_pack, system/ai/llm_client
script: test/passage_weather_briefing_dialog_test.dart
source: lib/ui/weather/passage_weather_briefing_dialog.dart
