title: Anchor watch and alarm
desc: Tracks distance from the dropped anchor against the swing radius (and optional danger zone) and raises the alarm when the boat drags.
layer: platform
keywords: anchor, alarm, drag, radius, swing circle, watch
kind: service
looks: -
reach: Anchor Alarm after Drop Anchor Here; polled while the watch is active
needs: platform=device
action: Computes distance from anchor each position update and alarms outside the radius.
expect: Alarm fires when the boat leaves the circle; stays quiet inside it.
uses: system/platform/boat_position
script: test/anchor_alarm_service_test.dart
source: lib/services/anchor_alarm_service.dart (AnchorAlarmService)
