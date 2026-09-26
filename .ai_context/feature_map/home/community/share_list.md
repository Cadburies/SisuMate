title: Share a list with the community
desc: Publish one of your checklists, briefings or service schedules to the community library.
layer: ux
keywords: share, publish, upload, contribute, template
kind: dialog
looks: Share button in the Community title bar; opens "Choose a list to share" with all your lists by type.
reach: text:Community > tip:Share one of your lists
needs: tier=pro
action: Pick a list to publish it; publishing needs a connection and a boat account.
expect: "Choose a list to share" lists your checklists, briefings and schedules.
uses: system/sync/community
script: community
source: lib/ui/community/community_browser_screen.dart (CommunityBrowserScreen); lib/services/community_share.dart
