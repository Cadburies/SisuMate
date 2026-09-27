title: Community templates sync
desc: Publishing lists to the community library, browsing and importing templates, keeping them offline, and reporting bad ones.
layer: sync
keywords: community, templates, publish, import, offline store, report
kind: service
looks: -
reach: Community library actions (Pro)
needs: network=online
action: Share uploads a sanitised copy of a list; import merges a template into your own lists; kept templates are stored on the device.
expect: Imported templates merge without duplicating existing items.
uses: -
script: test/community_merge_test.dart
source: lib/services/community_share.dart; lib/services/community_merge.dart; lib/services/community_offline_store.dart (CommunityOfflineStore)
