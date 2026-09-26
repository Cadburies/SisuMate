title: Record page
desc: The full page used by Fuel & Water, Inventory, Crew, Documents and the engine hours log for one record, with Edit, Delete, photo and paging.
layer: ux
keywords: record, detail, edit, delete, photo, page
kind: screen
looks: Record title, "N of M", its fields, Delete and Edit buttons, and a photo button.
reach: text:Inventory > tip:Add inventory item > type:Name=Spare impeller > text:Save > text:Spare impeller
needs: tier=pro
action: Edit switches the fields to editable; Delete removes the record; swipe sideways for the next record.
expect: "1 of 1" with Delete and Edit is shown.
uses: -
script: inventory
source: lib/ui/components/record_detail_screen.dart (RecordDetailScreen)
