title: Boat enrollment
desc: Links a boat to the owner's account in the cloud and issues the crew share code.
layer: auth
keywords: enrollment, boat account, share code, owner, claim boat
kind: service
looks: -
reach: creating a boat account, Share this boat
needs: network=online
action: Registers the boat server-side and returns its share code.
expect: The owner can show a code that crew can redeem.
uses: -
script: test/boat_enrollment_service_test.dart
source: lib/services/boat_enrollment_service.dart (BoatEnrollmentService)
