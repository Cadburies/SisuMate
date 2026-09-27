title: Trip schedule
desc: The planned trip window (departure and return) that drives checklist autopilot and readiness.
layer: logic
keywords: trip, schedule, departure date, dates
kind: service
looks: -
reach: set from trip planning; read by autopilot and readiness
needs: -
action: Works out the trip phase from today's date.
expect: The phase (before departure, underway, arrival) matches the dates.
uses: -
script: test/trip_schedule_test.dart
source: lib/services/trip_schedule.dart
