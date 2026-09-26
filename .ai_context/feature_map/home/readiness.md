title: Passage readiness card
desc: A card at the top of Home that says whether the boat is ready for passage and lists anything blocking it.
layer: ux
keywords: ready, passage, readiness, blockers, departure, safety, overdue
kind: card
looks: Card above the tiles with a tick ("Ready for passage") or a warning icon and a list of blockers.
reach: wait:Ready for passage
needs: -
action: Combines safety checklist progress, overdue maintenance, wind and fuel into one verdict. Swipe the card away to hide it until the app restarts.
expect: "Ready for passage" (or the blockers) is shown above the tiles.
uses: system/logic/passage_readiness
script: home
source: lib/ui/home/home_screen.dart (_PassageReadinessCard, homePassageReadinessDismissedProvider)
