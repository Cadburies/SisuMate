title: Polar improvement (offline first)
desc: Cleans the boat's polar samples on the device (outliers removed, curves smoothed); an AI pass is optional.
layer: ai
keywords: polar, improve, smooth, outliers, offline
kind: service
looks: -
reach: Boat Polar Data / Polar diagram → Improve offline / Improve with AI
needs: -
action: Local smoothing first; the LLM path runs only on "Improve with AI" with a key.
expect: Improve offline works with no connection and no key.
uses: system/ai/llm_client
script: test/polar_local_improve_test.dart
source: lib/services/polar_local_improve.dart (PolarLocalImprove); lib/services/polar_llm_improve_service.dart (PolarLlmImproveService)
