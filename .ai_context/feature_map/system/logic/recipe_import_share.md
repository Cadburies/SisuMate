title: Recipe import and sharing
desc: Imports recipes from a web page and shares recipes or records as text/files.
layer: logic
keywords: import recipe, url, share recipe, export
kind: service
looks: -
reach: Chef → Add recipe → Import from URL; Print / Share
needs: -
action: Parses the page into a recipe; share builds a readable export.
expect: A recipe page URL becomes a recipe with ingredients.
uses: -
script: test/recipe_import_service_test.dart
source: lib/services/recipe_import_service.dart (RecipeImportService); lib/services/recipe_share_service.dart (RecipeShareService); lib/services/record_share_service.dart (RecordShareService)
