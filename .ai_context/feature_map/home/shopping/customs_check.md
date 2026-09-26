title: Customs check
desc: Check items you are carrying (drones, spearguns, fresh meat, spirits) against an offline customs reminder pack, or ask AI about a pasted excerpt.
layer: ux
keywords: customs, clearance, declare, import rules, border, drone, spirits
kind: dialog
looks: Passport-style button in the Shopping title bar; opens "Customs check".
reach: text:Shopping > tip:Customs check (list)
needs: -
action: "Check offline pack" works with no internet; the AI option needs a connection and a key. Not an official customs determination.
expect: "Customs check" with "Check offline pack" is shown.
uses: system/ai/compliance_pack
script: shopping
source: lib/ui/shopping/customs_check_dialog.dart
