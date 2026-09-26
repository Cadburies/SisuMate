title: Guest profiles
desc: Save each guest's allergens and dietary needs once and load them when planning meals.
layer: ux
keywords: guests, profiles, allergies, diet, dietary requirements, charter
kind: screen
looks: "Load Profile" on Chef's Corner opens a sheet; "Manage Profiles" opens the profiles list with a + button.
reach: text:Chef > text:Chef's Corner > text:Load Profile > text:Manage Profiles
needs: -
action: Add, edit or remove guest profiles; loading one sets the allergen and diet chips.
expect: The guest profiles screen opens.
uses: -
script: chef
source: lib/ui/chef/guest_profiles_screen.dart (GuestProfilesScreen)
