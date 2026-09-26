title: Sign in by email link
desc: An older sign-in that emails you a magic link. The main account flow is Boat account in the menu.
layer: ux
keywords: sign in, login, magic link, email, account
kind: dialog
looks: "Sign In / Sign in to sync data (Pro only)" under Account; opens a dialog asking for your email.
reach: tip:Menu > text:Settings > text:Sign In
needs: network=online
action: Sends a sign-in link to the email address.
expect: The dialog asks for your email with "Send Magic Link".
uses: system/auth/auth
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen); lib/services/auth_service.dart (signInWithMagicLink)
