title: Sign-in and accounts
desc: Owner accounts (email + password sign up / sign in), anonymous crew sessions, sign out, and the developer-account check.
layer: auth
keywords: auth, sign in, sign up, password, anonymous, crew, developer
kind: service
looks: -
reach: Boat account and Join a boat screens, menu Sign Out
needs: network=online
action: Wraps Supabase auth; the developer check only gates the console UI, and every admin call is re-checked on the server.
expect: Signed-in state drives the menu's Account section and sync eligibility.
uses: -
script: test/auth_service_test.dart
source: lib/services/auth_service.dart (AuthService); lib/services/auth_backend.dart
