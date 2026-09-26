title: Plan passage from the anchorage
desc: Opens the passage planner starting from where you are anchored.
layer: ux
keywords: plan passage, route, leave, next stop, handoff
kind: button
looks: "Plan passage" among the watch buttons.
reach: text:Anchor Alarm > text:Drop Anchor Here > text:Plan passage
needs: platform=device
action: Opens the Weather passage planner with the anchor as the start.
expect: The Passage Planner opens with the anchor position as waypoint 1.
uses: home/weather/passage_planner
script: test/anchor_alarm_screen_test.dart
source: lib/ui/anchor/anchor_alarm_screen.dart (AnchorAlarmScreen); lib/ui/passage_handoff.dart
