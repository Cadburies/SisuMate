title: Photos and image fallback
desc: Takes or picks photos for items, stores them locally, and falls back from local file to remote copy to bundled placeholder.
layer: network
keywords: photos, images, camera, gallery, fallback, placeholder
kind: service
looks: -
reach: Change photo / Add photo on any item or record
needs: -
action: Saves picked images on the device; SmartImage resolves local → remote → asset.
expect: Items always show an image or a placeholder, never a broken tile.
uses: -
script: test/image_fallback_service_test.dart
source: lib/services/image_service.dart (ImageService); lib/services/image_fallback_service.dart (ImageFallbackService)
