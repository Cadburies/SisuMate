title: Mixologist
desc: Ranks the cocktails you can make tonight from what is in My Bar, and invents a drink to match a vibe, occasion, strength and glass.
layer: ux
keywords: mixologist, what can i make, suggest, invent, vibe, rank
kind: screen
looks: "Mixologist" tab: "What can I make tonight?", then "Invent a drink" with vibe and occasion chips, strength, glassware and "Suggest a Cocktail".
reach: text:Cocktails > text:Mixologist > wait:What can I make tonight?
needs: -
action: Rank uses bar stock; Suggest a Cocktail invents one on the device, with no internet needed.
expect: "What can I make tonight?" and "Invent a drink" are shown.
uses: system/logic/mixologist
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (_MixologistTab); lib/services/mixologist_service.dart (MixologistService)
