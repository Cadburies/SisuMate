title: Boat options
desc: Edit a boat's details from its options menu.
layer: ux
keywords: edit boat, rename, boat details, options
kind: menu
looks: Three-dot menu on each boat in My Boats.
reach: tip:Menu > text:Settings > text:Manage Boats > tip:Boat options: My Boat
needs: tier=pro
action: Edit opens the boat's details.
expect: "Edit" is offered.
uses: -
script: account
source: lib/ui/boats/boats_screen.dart (BoatsScreen)
