title: Profile heartbeat
desc: Records when this account was last seen and its real subscription state, so stale cloud data can be found and purged later.
layer: auth
keywords: heartbeat, last seen, stale data, subscription state
kind: job
looks: -
reach: after Home appears on every launch
needs: network=online
action: Stamps last-seen and plan on the profile; used by the developer console's stale-data purge.
expect: The profile's last-seen date updates once per launch.
uses: -
script: test/profile_heartbeat_test.dart
source: lib/services/profile_heartbeat.dart (ProfileHeartbeat)
