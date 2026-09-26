title: Report or keep a template
desc: Flag a community template that is wrong or inappropriate, or keep one for offline use.
layer: ux
keywords: report, flag, abuse, keep, offline, template
kind: button
looks: Flag and keep buttons on each template card.
reach: text:Community
needs: tier=pro · network=online · platform=device
action: Report sends the template for review; keep stores it on this device.
expect: Reported templates are hidden for you; kept ones show under "On this device".
uses: system/sync/community
script: test/community_report_test.dart
source: lib/ui/community/community_browser_screen.dart (CommunityBrowserScreen); lib/services/community_offline_store.dart
