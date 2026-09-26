title: Community library
desc: Browse and import checklists, briefings and service schedules shared by other sailors, filtered to your boat's engines and gear. Pro only.
layer: ux
keywords: community, templates, library, share, download, other sailors
kind: screen
looks: "Community Library" with filter chips (All, On this boat, On this device), sort chips (Recent, Most Downloaded) and a share button.
reach: text:Community
needs: tier=pro (Free shows "Community Library is Pro only" with Upgrade to Pro)
action: Browse templates and import one into your own lists; filters narrow to your boat.
expect: The library opens with its filter and sort chips (empty until templates are published or you are online).
uses: system/sync/community
script: community
source: lib/ui/community/community_browser_screen.dart (CommunityBrowserScreen)
