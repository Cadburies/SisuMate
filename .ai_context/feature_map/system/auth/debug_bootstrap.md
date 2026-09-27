title: Debug bootstrap (developer builds)
desc: In debug builds with the Pro testing switch on, signs the developer's owner account in and makes the "Sisu" boat active, so on-device sync can be tested without the sign-up flow.
layer: auth
keywords: debug, bootstrap, developer, testing, force pro
kind: job
looks: -
reach: after Home appears, debug builds only
needs: build=debug
action: Skips entirely for anonymous crew sessions and when no credentials are configured.
expect: Release builds never run it.
uses: system/auth/auth
script: test/debug_bootstrap_test.dart
source: lib/services/debug_bootstrap.dart (DebugBootstrap)
