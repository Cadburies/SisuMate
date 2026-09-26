title: Drop anchor
desc: Sets the anchor at the boat's current position and starts the watch.
layer: ux
keywords: drop anchor, set anchor, start watch, anchor here
kind: button
looks: "Drop Anchor Here" on the Watch tab (shows "Waiting for a GPS fix…" until there is a position).
reach: text:Anchor Alarm > text:Drop Anchor Here
needs: platform=device
action: Records the anchor position; the swing circle and alarm follow the scope and radius settings.
expect: The anchor appears on the chart with its circle, and the watch buttons (Save this spot, Weigh anchor…) show.
uses: system/platform/anchor_alarm
script: test/anchor_alarm_screen_test.dart
source: lib/ui/anchor/anchor_alarm_screen.dart (AnchorAlarmScreen)
