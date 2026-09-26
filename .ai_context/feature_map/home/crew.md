title: Crew & Contacts
desc: Your crew and contacts: role, phone, email, emergency contact, certifications and nationality.
layer: ux
keywords: crew, contacts, people, guests, emergency contact, roster
kind: screen
looks: "Crew & Contacts" list with role under each name; AI, select, import/export and + buttons.
reach: text:Crew & Contacts
needs: -
action: Tap a person for their page; + adds someone.
expect: "No crew members yet" on a fresh install.
uses: -
script: crew
source: lib/ui/crew/crew_screen.dart (CrewScreen)
