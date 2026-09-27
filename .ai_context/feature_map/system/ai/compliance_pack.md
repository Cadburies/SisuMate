title: Offline compliance pack
desc: Bundled keyword rules that flag safety-gear and customs issues (flares, EPIRB, drones, spirits…) offline; AI reading of a pasted excerpt is optional.
layer: ai
keywords: compliance, customs, safety gear, flares, rules, offline
kind: service
looks: -
reach: Safety compliance check, Shopping customs check, shop guide
needs: -
action: Matches item text against bundled rules and returns hits with severity; reminders only, not legal advice.
expect: Known red-flag items produce a hit; clean items say no flag matched.
uses: system/ai/llm_client
script: test/compliance_pack_service_test.dart
source: lib/services/compliance_pack_service.dart (CompliancePackService, ComplianceHit)
