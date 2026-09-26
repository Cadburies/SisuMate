title: About Sisu Mate
desc: Shows the app version and where to find tutorials, privacy policy and terms.
layer: ux
keywords: about, version, info, help, youtube, privacy, terms
kind: dialog
looks: "About" row at the bottom of the menu; opens an "About Sisu Mate" dialog with a Close button.
reach: tip:Menu > text:About
needs: -
action: Opens the About dialog.
expect: "About Sisu Mate" with the version is shown.
uses: -
script: home
source: lib/ui/components/common_drawer.dart (_showAboutDialog)
