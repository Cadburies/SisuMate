title: Game computer players
desc: Local computer opponents for every game, with skill levels and play styles, deterministic under a fixed seed; never uses the network.
layer: ai
keywords: game ai, computer player, difficulty, persona, bot
kind: service
looks: -
reach: any solo game, and AI seats in multiplayer lobbies
needs: -
action: Picks moves by skill level and persona with a seeded random generator.
expect: The same seed gives the same move; no network calls.
uses: -
script: test/game_ai_determinism_test.dart
source: lib/services/game_ai/game_ai_difficulty.dart; lib/services/game_ai/game_ai_persona.dart (GameAiSeatPreset); lib/services/game_ai/game_ai_rng.dart
