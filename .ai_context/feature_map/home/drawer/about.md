title: About Sisu Mate
desc: Shows the app version and licence, with buttons for the privacy policy and the open-source licences.
layer: ux
keywords: about, version, info, help, youtube, privacy, terms, licence, license
kind: dialog
looks: "About" row at the bottom of the menu; opens an "About Sisu Mate" dialog with Privacy, Licences and Close buttons.
reach: tip:Menu > text:About
needs: -
action: Opens the About dialog.
expect: "About Sisu Mate" with the version and the Apache 2.0 licence line is shown.
uses: home/drawer/settings/legal, home/drawer/settings/licences
script: home
source: lib/ui/components/common_drawer.dart (AboutSection)
