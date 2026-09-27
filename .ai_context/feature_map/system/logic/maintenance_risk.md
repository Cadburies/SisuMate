title: Maintenance risk scoring
desc: Ranks recurring maintenance tasks by risk from interval, last-done hours/dates and criticality, fully offline.
layer: logic
keywords: risk, triage, maintenance, overdue, priority
kind: service
looks: -
reach: Engine Hours & Service Log → triage
needs: -
action: Scores each task and labels it LOW / MEDIUM / HIGH with a reason.
expect: A task with no last-done hours is flagged with that reason.
uses: -
script: test/maintenance_risk_scorer_test.dart
source: lib/services/maintenance_risk_scorer.dart (MaintenanceRiskScorer, MaintenanceRiskItem)
