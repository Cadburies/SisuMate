title: Local sharing over Wi-Fi
desc: Sends items (e.g. saved anchorages or lists) directly to another phone on the same Wi-Fi, without the cloud.
layer: lan
keywords: share, local, wifi, nearby, send, receive
kind: service
looks: -
reach: share actions that offer "nearby device"
needs: platform=device
action: Discovers a nearby receiver and transfers the payload over the local network.
expect: The other phone receives the shared item.
uses: -
script: test/share_lan_service_test.dart
source: lib/services/lan/share_lan_service.dart
