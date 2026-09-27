title: Sea state from the phone's motion sensors
desc: Estimates heave and sea state (smooth, moderate, rough) from the phone's accelerometer when instruments can't tell.
layer: platform
keywords: imu, accelerometer, heave, sea state, waves, motion
kind: service
looks: -
reach: during polar sampling on devices with motion sensors
needs: platform=device
action: Samples acceleration, estimates heave and a confident sea-state class.
expect: Rough water yields "rough"; low confidence is ignored.
uses: -
script: test/imu_heave_estimator_test.dart
source: lib/services/imu_sea_state_service.dart (ImuSeaStateService); lib/services/imu_heave_estimator.dart (ImuHeaveEstimator); lib/services/sea_state_estimator.dart (SeaStateEstimator)
