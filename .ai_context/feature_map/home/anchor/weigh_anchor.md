title: Weigh anchor
desc: Ends the anchor watch when you leave. Saved spots are kept.
layer: ux
keywords: weigh anchor, stop watch, leave, lift anchor
kind: button
looks: "Weigh anchor" among the watch buttons once the anchor is down.
reach: text:Anchor Alarm > text:Drop Anchor Here > text:Weigh anchor
needs: platform=device
action: Stops the watch and clears the live anchor.
expect: The Watch tab returns to "No anchor set".
uses: -
script: test/anchor_alarm_screen_test.dart
source: lib/ui/anchor/anchor_alarm_screen.dart (AnchorAlarmScreen)
