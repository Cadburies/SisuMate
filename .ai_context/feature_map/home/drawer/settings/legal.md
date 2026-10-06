title: Privacy policy, terms and support
desc: The Legal part of Settings: links to the privacy policy, terms of use, support page and how to delete your account, all on the Sisu Mate website.
layer: ux
keywords: legal, privacy, privacy policy, terms, terms of use, support, help, delete account, gdpr
kind: tile
looks: "Legal" section at the bottom of Settings with Privacy Policy, Terms of Use, Support and Delete account (web), each with an open-in-browser icon.
reach: tip:Menu > text:Settings > text:Privacy Policy
needs: network=online (the pages open in the browser)
action: Opens the page in the browser; shows "Could not open …" if no browser can open it.
expect: The privacy policy URL is handed to the browser.
uses: -
script: settings
source: lib/ui/components/common_drawer.dart (LegalSection, LegalLinks, openLegalLink); lib/ui/settings/settings_screen.dart
