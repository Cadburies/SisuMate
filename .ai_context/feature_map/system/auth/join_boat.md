title: Crew join by share code
desc: A crew member redeems the captain's share code first; only a valid code switches the phone to the captain's boat, restamps local rows to that boat and starts sync.
layer: auth
keywords: join boat, crew, share code, redeem, restamp, enroll
kind: service
looks: -
reach: Join a boat → Join boat
needs: network=online
action: Redeem → local boat upsert → set active boat → restamp content → start sync; an invalid code never half-enrols.
expect: Valid code: the phone shows the captain's boat and lists; invalid: nothing changes.
uses: system/sync/wire_prefix, system/sync/eligibility
script: test/join_boat_flow_test.dart
source: lib/services/join_boat_service.dart (JoinBoatService)
