title: Account (menu)
desc: The Account part of every menu: create or sign in to a boat account, join a boat with a share code, and, when signed in, share the boat or sign out.
layer: ux
keywords: account, sign in, login, join boat, crew, share code, sign out
kind: menu
looks: Account section in the main menu with "Boat account" and "Join a boat" (signed out), or your email with Share this boat and Sign Out (signed in).
reach: tip:Menu
needs: auth=none
action: Opens the account screens; signed-in owners also get "Share this boat" and the developer console when applicable.
expect: "Boat account" and "Join a boat" are shown when signed out.
uses: -
script: account
source: lib/ui/components/common_drawer.dart (AccountSection)
