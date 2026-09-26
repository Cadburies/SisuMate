title: Change an item photo
desc: Add or replace the photo on an item, from the camera or your gallery.
layer: ux
keywords: photo, picture, image, camera, gallery, attach
kind: button
looks: Camera icon button on the item page's photo.
reach: text:Checklists > text:Last Minute Departure Checks > text:Final Weather Check > tip:Change photo
needs: -
action: Opens a sheet to choose Camera or Gallery.
expect: A sheet offers "Camera" and "Gallery".
uses: -
script: shared_components
source: lib/ui/components/photo_source_picker.dart; lib/ui/components/item_detail_shell.dart (ItemDetailShell)
