title: Maintenance risk triage
desc: Ranks your recurring tasks by risk using local rules, with an optional AI write-up when online.
layer: ux
keywords: triage, risk, priority, overdue, what first, ai
kind: dialog
looks: Purple sparkle button in the Engine Hours title bar (greyed out until there is at least one task).
reach: text:Maintenance > tip:Engine Hours & Service Log > tip:Add maintenance task > type:Description=Change impeller > type:Interval (engine hours)=250 > text:Save > tip:AI: Risk-ranked maintenance triage
needs: -
action: Shows the offline risk ranking; "Explain with AI" adds a narrative when online with an AI key.
expect: "Maintenance risk triage" lists "[LOW] Change impeller" under the offline rules.
uses: system/logic/maintenance_risk
script: maintenance
source: lib/ui/maintenance/maintenance_risk_triage_dialog.dart (MaintenanceRiskTriageDialog); lib/services/maintenance_risk_scorer.dart
