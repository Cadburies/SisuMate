title: Email composer
desc: Builds emails (shopping lists, provision lists, share codes) with your sender name, reply-to and boat name, and opens the phone's mail app.
layer: network
keywords: email, mail, send, share, signature
kind: service
looks: -
reach: Email All Lists, Email provision list, share-code Email
needs: platform=device
action: Composes subject and body from settings and opens the mail app.
expect: The mail app opens pre-filled.
uses: -
script: test/email_service_test.dart
source: lib/services/email_service.dart (EmailService)
