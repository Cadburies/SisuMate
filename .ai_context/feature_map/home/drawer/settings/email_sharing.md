title: Email and sharing
desc: Set the sender name, reply-to address and boat name used when the app emails lists and reports.
layer: ux
keywords: email, sharing, signature, reply-to, boat name, send
kind: field
looks: "Email & Sharing" section with From name, Reply-to email and Boat name fields.
reach: tip:Menu > text:Settings > type:From name (email signature)=Skipper Sam
needs: -
action: The details are used in the subject and signature of emails the app composes.
expect: The name is kept for the next email.
uses: -
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen)
