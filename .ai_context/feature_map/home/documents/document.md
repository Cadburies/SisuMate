title: A document
desc: One document in full, with Edit and Delete.
layer: ux
keywords: document, detail, edit, delete, photo
kind: screen
looks: Document page with "N of M", Title, Type, Belongs to, Delete and Edit.
reach: text:Documents > tip:Add document > type:Title=Hull policy > text:Registration > text:Insurance > text:Save > text:Hull policy
needs: tier=pro
action: Edit or delete the document; swipe sideways for the next one.
expect: "1 of 1" with Type "Insurance" is shown.
uses: shared/record_detail
script: documents
source: lib/ui/documents/documents_screen.dart (DocumentsScreen); lib/ui/components/record_detail_screen.dart (RecordDetailScreen)
