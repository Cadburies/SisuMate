title: Create a boat account
desc: Create an owner account (email, password and boat name) so the boat can sync across devices and be shared with crew. Sync needs Pro.
layer: ux
keywords: sign up, create account, register, owner, boat account, sync
kind: screen
looks: "Create Boat Account" screen with Email, Password and Boat name fields and "Create account".
reach: tip:Menu > text:Boat account
needs: auth=none
action: Creates the account and links the boat; needs a connection.
expect: "Create your boat account" with "Create account" is shown.
uses: system/auth/auth
script: account
source: lib/ui/account/account_setup_screen.dart (AccountSetupScreen)
