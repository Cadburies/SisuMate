title: Sort community templates
desc: Show the newest templates first or the most downloaded.
layer: ux
keywords: sort, recent, popular, most downloaded
kind: chip
looks: "Recent" and "Most Downloaded" chips on the Community Library.
reach: text:Community > text:Most Downloaded
needs: tier=pro
action: Re-orders the templates.
expect: Templates are listed by download count.
uses: -
script: community
source: lib/ui/community/community_browser_screen.dart (CommunityBrowserScreen)
