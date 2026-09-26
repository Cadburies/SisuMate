title: Sign out
desc: Signs this device out of the boat account.
layer: ux
keywords: sign out, log out, logout
kind: menu
looks: "Sign Out" in the menu when signed in.
reach: tip:Menu > text:Sign Out
needs: auth=owner · platform=device
action: Signs out; local data stays on the device.
expect: The menu shows "Boat account" and "Join a boat" again.
uses: system/auth/auth
script: -
source: lib/ui/components/common_drawer.dart (AccountSection)
