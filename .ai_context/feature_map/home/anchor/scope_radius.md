title: Scope and alarm radius
desc: Set the rode scope ratio and the alarm radius (and an optional danger zone) for the anchor watch.
layer: ux
keywords: scope, radius, rode, chain, swing circle, danger zone
kind: card
looks: "Scope & Alarm Radius" card on the Watch tab with a scope ratio slider (e.g. 5.0:1) and radius controls.
reach: text:Anchor Alarm > wait:Scope & Alarm Radius
needs: platform=device
action: Adjusts how far the boat may swing before the alarm sounds.
expect: The circle on the chart resizes as you change the values.
uses: -
script: test/anchor_alarm_screen_test.dart
source: lib/ui/anchor/anchor_alarm_screen.dart (AnchorAlarmScreen)
