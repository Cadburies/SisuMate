title: My boats
desc: List, add and edit your boats. Free covers one boat; more boats need Pro.
layer: ux
keywords: boats, my boats, fleet, add boat, rename boat, multiple boats
kind: screen
looks: "Manage Boats" in Settings opens "My Boats" with a + button and an options menu per boat (Free shows "Upgrade to Pro for multiple boats" instead).
reach: tip:Menu > text:Settings > text:Manage Boats
needs: tier=pro (Free has one boat; the row offers an upgrade instead)
action: Add a boat, or edit one from its options menu.
expect: "My Boats" lists "My Boat".
uses: home/drawer/settings/active_boat
script: account
source: lib/ui/boats/boats_screen.dart (BoatsScreen)
