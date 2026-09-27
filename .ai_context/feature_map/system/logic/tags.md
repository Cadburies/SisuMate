title: Tag library
desc: The shared list of cuisine, style and flavour tags used by recipe editors, learning new phrases as you type them.
layer: logic
keywords: tags, cuisine, flavour, labels
kind: service
looks: -
reach: recipe and cocktail editors
needs: -
action: Suggests existing tags and saves new ones for next time.
expect: A new tag appears in suggestions next time.
uses: -
script: test/tag_library_service_test.dart
source: lib/services/tag_library_service.dart (TagLibraryService)
