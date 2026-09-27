title: Barcode scanning
desc: Scans product barcodes with the camera to fill inventory items and match pantry/bar products.
layer: platform
keywords: barcode, scan, camera, product, ean
kind: service
looks: -
reach: "Scan barcode" on inventory and ingredient forms
needs: platform=device
action: Opens the scanner and matches the code to known items.
expect: The barcode field fills; a known product is matched.
uses: -
script: test/barcode_service_test.dart
source: lib/services/barcode_service.dart (BarcodeService, BarcodeMatch)
