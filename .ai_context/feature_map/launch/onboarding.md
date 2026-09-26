title: Welcome tour
desc: Five short pages shown on first launch: welcome, how lists work, the modules, Pro, and getting started.
layer: ux
keywords: onboarding, welcome, tour, intro, first run, tutorial
kind: screen
looks: Full-screen coloured pages with a large icon, page dots at the bottom, Next on the right and Skip at the top.
reach: -
needs: onboarding=unseen
action: Swipe or tap Next to move through the pages; Skip or Get Started ends the tour.
expect: "Welcome to Sisu Mate" page is shown.
uses: -
script: launch
source: lib/ui/onboarding/onboarding_screen.dart (OnboardingScreen, hasSeenOnboarding)
