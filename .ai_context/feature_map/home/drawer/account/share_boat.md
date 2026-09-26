title: Share this boat
desc: Show the crew join code for the active boat, and copy, share or email it.
layer: ux
keywords: share boat, crew code, invite crew, join code
kind: dialog
looks: "Share this boat" in the menu when signed in as the owner; opens "Share <boat>" with the code and Copy, Share, Email.
reach: tip:Menu > text:Share this boat
needs: auth=owner · platform=device
action: Shows the code for crew to enter under Join a boat.
expect: The dialog shows the boat's join code.
uses: system/auth/join_boat
script: test/drawer_navigation_test.dart
source: lib/ui/components/common_drawer.dart (AccountSection)
