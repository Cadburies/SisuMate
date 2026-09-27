title: Barcode scanner
desc: Scan a product barcode with the camera to fill it in on an inventory item or match a pantry or bar product.
layer: ux
keywords: barcode, scan, camera, product, ean, upc
kind: screen
looks: Full-screen camera view with a scanning frame, opened from "Scan barcode" buttons.
reach: text:Inventory > tip:Add inventory item > tip:Scan barcode
needs: platform=device
action: Point the camera at the barcode; the code fills the form, and known products are matched.
expect: The barcode field is filled after a successful scan.
uses: system/platform/barcode
script: test/barcode_service_test.dart
source: lib/ui/cocktails/cocktails_screen.dart (BarcodeScannerScreen)