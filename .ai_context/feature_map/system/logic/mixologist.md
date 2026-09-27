title: Mixologist engine
desc: Ranks makeable cocktails from bar stock (with substitutes), invents drinks by vibe and occasion, and flags low bar stock, all offline.
layer: logic
keywords: mixologist, cocktails, makeable, substitutes, invent
kind: service
looks: -
reach: Cocktails → Mixologist
needs: -
action: Scores each recipe by stock on hand; generates a suggestion locally.
expect: Ranking lists "Have N · missing: …" per drink.
uses: -
script: test/mixologist_service_test.dart
source: lib/services/mixologist_service.dart (MixologistService, MakeableRecipeScore)
