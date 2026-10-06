title: Insurance claim check
desc: On an insurance document, check an incident against policy wording you paste. An offline keyword reading comes first. Improve with AI is optional.
layer: ux
keywords: insurance, claim, policy, damage, coverage, ai, offline
kind: dialog
looks: Purple sparkle badge on insurance documents only; opens "AI: Insurance claim check".
reach: text:Documents > tip:Add document > type:Title=Hull policy > text:Registration > text:Insurance > text:Save > tip:Insurance claim check: Hull policy
needs: tier=pro
action: Paste the policy excerpt, describe the incident, and tap Check offline. Improve with AI is optional.
expect: "AI: Insurance claim check" with a Check offline button is shown.
uses: system/ai/llm_client
script: documents
source: lib/ui/documents/insurance_claim_check_dialog.dart (InsuranceClaimCheckDialog); lib/ui/components/pasted_excerpt_check_dialog.dart (PastedExcerptCheckDialog); lib/services/pasted_excerpt_local_check.dart
