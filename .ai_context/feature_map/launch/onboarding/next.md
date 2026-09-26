title: Next page
desc: Moves the welcome tour to its next page.
layer: ux
keywords: next, continue, onboarding, tour
kind: button
looks: Green "Next" button, bottom-right of each tour page except the last.
reach: text:Next
needs: onboarding=unseen
action: Slides to the next tour page.
expect: The "How to use" page about lists and colours is shown.
uses: -
script: launch
source: lib/ui/onboarding/onboarding_screen.dart (_next)
