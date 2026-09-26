title: Weather safety briefing
desc: A briefing on the weather risks along your planned passage, using the cached forecast.
layer: ux
keywords: briefing, weather risk, safety, passage, ai
kind: dialog
looks: Purple sparkle button in the Passage Planner title bar; opens "AI: Weather safety briefing".
reach: text:Weather > tip:Passage planner > tip:AI: Weather safety briefing
needs: -
action: Summarises the forecast along the route; it needs a forecast loaded for the area first.
expect: Without cached weather it says to load a forecast first.
uses: system/ai/weather_briefing
script: weather
source: lib/ui/weather/passage_weather_briefing_dialog.dart
