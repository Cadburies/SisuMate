title: Get Started
desc: Finishes the welcome tour from its last page and opens Home.
layer: ux
keywords: get started, finish, done, onboarding, tour
kind: button
looks: Green "Get Started" button on the last tour page ("Ready to cast off?").
reach: text:Next > text:Next > text:Next > text:Next > text:Get Started
needs: onboarding=unseen
action: Marks the tour as seen and opens Home.
expect: Home opens with the module tiles; the tour does not return on the next launch.
uses: -
script: launch
source: lib/ui/onboarding/onboarding_screen.dart (_finish)
