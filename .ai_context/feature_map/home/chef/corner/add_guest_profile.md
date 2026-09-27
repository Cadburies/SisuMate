title: Add a guest profile
desc: Record a guest's allergens and dietary requirements.
layer: ux
keywords: add guest, allergies, diet, profile
kind: fab
looks: Round + button on Guest profiles; opens "New Guest Profile".
reach: text:Chef > text:Chef's Corner > text:Load Profile > text:Manage Profiles > tip:Add guest profile
needs: -
action: Tick the guest's allergens and diets and save.
expect: "New Guest Profile" opens.
uses: -
script: chef
source: lib/ui/chef/guest_profiles_screen.dart (GuestProfilesScreen); lib/ui/chef/guest_profiles_screen.dart (AddEditGuestProfileDialog)
