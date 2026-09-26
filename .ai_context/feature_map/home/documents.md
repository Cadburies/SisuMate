title: Documents
desc: A vault for the boat's and crew's papers: registration, insurance, certificates, with expiry dates and photos.
layer: ux
keywords: documents, papers, registration, insurance, certificates, expiry, vault
kind: screen
looks: "Documents Vault" list with the type under each title; select, import/export and + buttons.
reach: text:Documents
needs: -
action: Tap a document for its page; + adds one; insurance documents get a claim-check button.
expect: "No documents yet" on a fresh install.
uses: -
script: documents
source: lib/ui/documents/documents_screen.dart (DocumentsScreen)
