title: Sign in to a boat account
desc: Sign in with the email and password of an existing boat account.
layer: ux
keywords: sign in, login, password, owner, account
kind: screen
looks: On the account screen, "Already have an account? Sign in" switches to "Sign in to your boat account".
reach: tip:Menu > text:Boat account > text:Already have an account? Sign in
needs: auth=none
action: Signs in and restores the boat; needs a connection.
expect: "Sign in to your boat account" with a Sign in button is shown.
uses: system/auth/auth
script: account
source: lib/ui/account/account_setup_screen.dart (AccountSetupScreen)
