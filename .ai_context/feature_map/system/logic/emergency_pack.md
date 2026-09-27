title: Emergency pack summary
desc: Collects what you need in an emergency (document expiries, safety gear, crew contacts) into one summary.
layer: logic
keywords: emergency, grab bag, documents, expiry, contacts
kind: service
looks: -
reach: Documents and safety views
needs: -
action: Builds a summary and flags expiring documents.
expect: Expiring documents are flagged.
uses: -
script: test/emergency_pack_service_test.dart
source: lib/services/emergency_pack_service.dart (EmergencyPackService, EmergencyPackSummary)
