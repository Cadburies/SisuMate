title: Anchor instruments
desc: Live readings at anchor: position and its source, wind, depth, speed and course over ground.
layer: ux
keywords: instruments, info, depth, wind, sog, cog, position
kind: screen
looks: "Info" tab with rows for position, apparent wind, depth, SOG and COG.
reach: text:Anchor Alarm > text:Info
needs: platform=device
action: Shows the latest readings; the refresh button re-reads the sources.
expect: Position, wind, depth, SOG and COG rows are shown.
uses: system/platform/boat_position
script: test/anchor_alarm_screen_test.dart
source: lib/ui/anchor/anchor_alarm_screen.dart (AnchorAlarmScreen); lib/ui/anchor/anchor_info_panel.dart
