title: A fuel or water fill
desc: One logged fill in full, with Edit and Delete, and paging to the other fills.
layer: ux
keywords: fill, entry, detail, edit, delete
kind: screen
looks: Fill page titled "<notes> • <volume>" with "N of M", the fields, and Delete and Edit.
reach: text:Fuel & Water > tip:Add fuel log > type:Volume (L)=40 > type:Notes=Marina fill > text:Save > text:Marina fill
needs: tier=pro
action: Edit or delete the fill; swipe sideways for the next one.
expect: "Marina fill • 40 L" and "1 of 1" are shown.
uses: shared/record_detail
script: fuel
source: lib/ui/fuel/fuel_screen.dart (FuelScreen); lib/ui/components/record_detail_screen.dart (RecordDetailScreen)
