title: Anchor Alarm
desc: Watches the boat's position at anchor and sounds an alarm if it drags outside the swing circle; shows live instruments.
layer: ux
keywords: anchor, anchor alarm, drag, swing circle, watch, anchorage
kind: screen
looks: "Anchor Alarm" with a Watch tab (chart, anchor controls, scope and radius) and an Info tab (position, wind, depth, SOG, COG).
reach: text:Anchor Alarm
needs: platform=device
action: Waits for a position from boat instruments or the phone's GPS, then lets you drop the anchor and set the alarm.
expect: The Watch tab shows "No anchor set" with "Drop Anchor Here" once a position is known.
uses: system/platform/anchor_alarm, system/platform/boat_position
script: test/anchor_alarm_screen_test.dart
source: lib/ui/anchor/anchor_alarm_screen.dart (AnchorAlarmScreen)
