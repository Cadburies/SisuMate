title: Public wiki publishing
desc: Regenerates the public GitHub wiki from the Feature Map (user features only, plain language) and pushes it.
layer: ops
keywords: wiki, publish, docs, help, feature map
kind: script
looks: -
reach: run scripts/publish_wiki.sh after any feature-map change (--dry-run to preview)
needs: network=online
action: Renders pages with tool/feature_map_wiki.dart, replaces the wiki contents, commits only on change.
expect: "wiki: published (feature map @ <sha>)".
uses: -
script: test/feature_map_wiki_test.dart
source: scripts/publish_wiki.sh; tool/feature_map_wiki.dart
