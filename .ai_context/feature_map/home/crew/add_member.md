title: Add a crew member
desc: Add a crew member or contact with role, phone, email, emergency contact, certifications, nationality and passport number. Pro only.
layer: ux
keywords: add, new crew, contact, person, guest
kind: fab
looks: Round + button on Crew & Contacts.
reach: text:Crew & Contacts > tip:Add crew member
needs: tier=pro (on Free it explains that editing needs Pro)
action: Opens the crew form; Save adds the person.
expect: After Save the person is listed with their role.
uses: -
script: crew
source: lib/ui/crew/crew_screen.dart (CrewScreen)
