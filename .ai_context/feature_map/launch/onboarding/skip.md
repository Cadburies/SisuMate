title: Skip the tour
desc: Ends the welcome tour straight away and opens Home; the tour will not show again.
layer: ux
keywords: skip, close, dismiss, onboarding, tour
kind: button
looks: "Skip" text button, top-right of every tour page except the last.
reach: text:Skip
needs: onboarding=unseen
action: Marks the tour as seen and opens Home.
expect: Home opens with the module tiles; the tour does not return on the next launch.
uses: -
script: launch
source: lib/ui/onboarding/onboarding_screen.dart (_finish, _markOnboardingSeen)
