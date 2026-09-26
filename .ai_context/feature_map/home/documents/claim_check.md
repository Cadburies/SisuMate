title: Insurance claim check
desc: On an insurance document, describe an incident and have the AI check it against your pasted policy wording. Currently needs an AI key and a connection.
layer: ux
keywords: insurance, claim, policy, damage, coverage, ai
kind: dialog
looks: Purple sparkle badge on insurance documents only; opens "AI: Insurance claim check".
reach: text:Documents > tip:Add document > type:Title=Hull policy > text:Registration > text:Insurance > text:Save > tip:Insurance claim check: Hull policy
needs: tier=pro · network=online
action: Paste the policy excerpt, describe the incident and tap Ask.
expect: "AI: Insurance claim check" with an Ask button is shown.
uses: system/ai/llm_client
script: documents
source: lib/ui/documents/insurance_claim_check_dialog.dart (InsuranceClaimCheckDialog); lib/ui/components/pasted_excerpt_check_dialog.dart
