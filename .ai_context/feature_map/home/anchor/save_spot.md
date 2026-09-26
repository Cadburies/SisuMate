title: Save an anchorage
desc: Save the current anchor spot as a named place with notes, to reuse, share or route to later.
layer: ux
keywords: save spot, anchorage, favourite, named place, bookmark
kind: dialog
looks: "Save this spot" among the watch buttons; saved places are listed under "Saved spots".
reach: text:Anchor Alarm > text:Drop Anchor Here > text:Save this spot
needs: platform=device
action: Name the spot and save; each saved spot can be routed to, shared, edited or deleted.
expect: The spot appears under "Saved spots".
uses: -
script: test/anchor_spot_repository_test.dart
source: lib/ui/anchor/save_anchor_spot_dialog.dart; lib/ui/anchor/share_anchor_spot_dialog.dart
