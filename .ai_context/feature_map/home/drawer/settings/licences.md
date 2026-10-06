title: Open-source licences
desc: Lists the licences of every open-source package in the app, plus the font licence and the cocktail photo credits.
layer: ux
keywords: licences, licenses, open source, credits, attribution, apache, copyright, font
kind: screen
looks: "Open-source licences" at the end of the Legal section in Settings (also the Licences button in About).
reach: tip:Menu > text:Settings > text:Open-source licences
needs: -
action: Opens the licence page, one entry per package.
expect: The licence page opens with "Sisu Mate" and the Apache 2.0 licence line.
uses: -
script: settings
source: lib/ui/components/common_drawer.dart (showSisuLicensePage); lib/services/bundled_licenses.dart (BundledLicenses)
