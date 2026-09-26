title: Rank my cocktails
desc: Lists cocktails in order of how close you are to making them from your bar, with what is missing.
layer: ux
keywords: rank, makeable, what can i make, missing, stock
kind: button
looks: "Rank my cocktails" button on Mixologist (appears once at least one bottle is in stock).
reach: text:Cocktails > text:My Bar > wait:Absinthe > swipe:Absinthe:In stock > text:Mixologist > wait:Rank my cocktails > text:Rank my cocktails
needs: -
action: Ranks every cocktail by stock on hand; close substitutes count, with notes.
expect: Drinks are listed with "Have N · missing: …" and the button becomes "Refresh ranking".
uses: system/logic/mixologist
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (_MixologistTab)
