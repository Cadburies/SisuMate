title: Safety compliance check
desc: Check a safety item (flares, EPIRB, liferaft service dates) against the offline pack of rules, or ask AI to read a pasted excerpt.
layer: ux
keywords: compliance, check, flares, epirb, liferaft, expiry, regulations, ai
kind: dialog
looks: Small purple sparkle badge on each briefing point; opens "Safety compliance check".
reach: text:Safety > text:Day Trip Safety Briefing > tip:Safety compliance check: Sunscreen
needs: -
action: "Check offline pack" works with no internet; "AI read of excerpt (online)" needs a connection and an AI key. Results are reminders, not a certified inspection.
expect: The "Safety compliance check" dialog with "Check offline pack" is shown.
uses: system/ai/compliance_pack
script: safety
source: lib/ui/safety/safety_compliance_check_dialog.dart (SafetyComplianceCheckDialog)
