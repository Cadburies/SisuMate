title: Add a document
desc: Add a document with title, type, notes, who it belongs to, expiry date and a photo. Pro only.
layer: ux
keywords: add, new document, upload, photo, expiry, insurance, registration
kind: fab
looks: Round + button on Documents; opens "Add Document".
reach: text:Documents > tip:Add document
needs: tier=pro (on Free it explains that editing needs Pro)
action: Save adds the document; pick the type from the Type list (Registration, Insurance and others).
expect: "Add Document" opens.
uses: -
script: documents
source: lib/ui/documents/documents_screen.dart (DocumentsScreen); lib/ui/documents/documents_screen.dart (AddEditDocumentDialog)
