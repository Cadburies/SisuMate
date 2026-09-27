title: Passage readiness verdict
desc: Combines safety checklist completion, overdue maintenance, wind and fuel range into one ready / not-ready verdict with blockers.
layer: logic
keywords: readiness, passage, ready, blockers, departure
kind: service
looks: -
reach: Home readiness card
needs: -
action: Each failing check becomes a blocker line.
expect: "Ready for passage" when nothing blocks; otherwise the blockers are listed.
uses: system/logic/fuel_burn_estimate
script: test/suggestion_engine_test.dart
source: lib/services/suggestion_engine.dart (PassageReadiness); lib/providers/passage_readiness_provider.dart
