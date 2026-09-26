title: Filter by engine make and model
desc: Tell the library which engines and gear are on your boat so "On this boat" shows only matching templates.
layer: ux
keywords: make, model, engine, yanmar, volvo, filter, my boat
kind: dialog
looks: "Add make / model" chip; opens a picker of makes (Yanmar, Volvo Penta, Perkins, Beta Marine…).
reach: text:Community > text:Add make / model
needs: tier=pro
action: Choose a make (and model) and tap Add; the "On this boat" filter uses it.
expect: The make picker with Cancel and Add is shown.
uses: -
script: community
source: lib/ui/community/community_browser_screen.dart (CommunityBrowserScreen)
