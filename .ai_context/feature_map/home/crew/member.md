title: A crew member
desc: One crew member or contact in full, with Edit and Delete.
layer: ux
keywords: crew, person, contact, detail, edit, delete
kind: screen
looks: Person page with "N of M", Name, Role and other fields, Delete and Edit.
reach: text:Crew & Contacts > tip:Add crew member > type:Name=Anna Smith > text:Save > text:Anna Smith
needs: tier=pro
action: Edit or delete the person; swipe sideways for the next one.
expect: "1 of 1" with Name and Role is shown.
uses: shared/record_detail
script: crew
source: lib/ui/crew/crew_screen.dart (CrewScreen); lib/ui/components/record_detail_screen.dart (RecordDetailScreen)
