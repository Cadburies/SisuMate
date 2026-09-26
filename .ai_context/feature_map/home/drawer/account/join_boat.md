title: Join a boat as crew
desc: Enter the share code from your captain to join their boat and see its lists on your phone.
layer: ux
keywords: join, crew, share code, boat code, captain, invite
kind: screen
looks: "Join a Boat" screen with "Enter the boat code", a code field (e.g. 4F2K9X) and "Join boat".
reach: tip:Menu > text:Join a boat
needs: auth=none
action: Checks the code with the server first; only a valid code switches this phone to the captain's boat. Needs a connection.
expect: "Enter the boat code" and "Join boat" are shown; an invalid code changes nothing.
uses: system/auth/join_boat
script: account
source: lib/ui/account/join_boat_screen.dart (JoinBoatScreen); lib/services/join_boat_service.dart
