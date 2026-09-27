title: Under-sail polar sampling
desc: While sailing (instruments online, engines off), stores boat-speed samples by wind angle and strength in the background and tags each with a sea state, building the boat's real polar.
layer: platform
keywords: polar, samples, sailing, background, sea state, performance
kind: job
looks: -
reach: background timer every 45 s while the app runs, once a boat is active
needs: platform=device
action: Rejects manoeuvres and engine-on periods, prefers STW over SOG, buckets samples for the polar chart.
expect: Sample counts grow while sailing; nothing is stored under engine or with no active boat.
uses: system/platform/boat_position, system/platform/imu_sea_state
script: test/feature_map_platform_collectors_test.dart
source: lib/services/polar_background_collector.dart (PolarBackgroundCollector); lib/services/sailing_polar_collector.dart (SailingPolarCollector); lib/services/polar_sample_eligibility.dart (PolarSampleEligibility); lib/services/polar_bucket_aggregator.dart (PolarBucketAggregator); lib/services/boat_polar_service.dart
