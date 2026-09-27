title: Device capabilities
desc: Detects what this device can do (GPS, motion sensors, camera, platform) so features degrade safely where hardware or plugins are missing.
layer: platform
keywords: capabilities, sensors, platform, fallback, plugins
kind: service
looks: -
reach: app start and before using sensors or plugins
needs: -
action: Reports availability flags; callers fall back instead of crashing.
expect: Missing plugins give a clean "unavailable", not an exception.
uses: -
script: test/platform_capabilities_test.dart
source: lib/core/platform_capabilities.dart (DeviceCapabilities)
