title: Add a boat
desc: Add another boat by name. Pro only.
layer: ux
keywords: add boat, new boat, second boat, fleet
kind: fab
looks: Round + button on My Boats; opens "Add New Boat".
reach: tip:Menu > text:Settings > text:Manage Boats > tip:Add boat
needs: tier=pro
action: Enter the boat name and tap Add Boat.
expect: "Add New Boat" opens; after Add Boat the new boat is listed.
uses: -
script: account
source: lib/ui/boats/boats_screen.dart (BoatsScreen)
