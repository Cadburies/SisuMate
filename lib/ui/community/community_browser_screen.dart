import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/title_tile.dart';
import '../../core/boat_engine_taxonomy.dart';
import '../../core/colors.dart';
import '../../core/di.dart';
import '../../domain/repositories/community_repository.dart';
import '../../models/models.dart';
import '../../providers/checklist_provider.dart';
import '../../services/community_merge.dart';
import '../../services/error_log_service.dart';
import '../../services/revenuecat_service.dart';

class CommunityBrowserScreen extends ConsumerStatefulWidget {
  const CommunityBrowserScreen({super.key});

  @override
  ConsumerState<CommunityBrowserScreen> createState() =>
      _CommunityBrowserScreenState();
}

class _CommunityBrowserScreenState
    extends ConsumerState<CommunityBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  CommunitySortOrder _sortBy = CommunitySortOrder.recent;
  List<CommunityTemplate> _templates = [];
  List<String> _interests = [];
  Set<String> _keptIds = {};
  bool _showKeptOnly = false;
  bool _fromCache = false;
  bool _fromKept = false;
  DateTime? _cachedAt;
  bool _loading = false;
  String? _error;

  // Must match ChecklistGroup.appType exactly ('safety', not 'safety_briefing')
  // — browsing by category has to line up with what import actually creates.
  static const _categories = [
    'all',
    'checklist',
    'maintenance',
    'safety',
  ];

  static String _categoryLabel(String cat) => switch (cat) {
        'all' => 'All',
        'safety' => 'Safety Briefing',
        _ => '${cat[0].toUpperCase()}${cat.substring(1)}',
      };

  @override
  void initState() {
    super.initState();
    _restoreOfflinePrefs();
  }

  Future<void> _restoreOfflinePrefs() async {
    if (!await ref.read(revenueCatProvider).isPro()) return;
    final repo = ref.read(communityRepositoryProvider);
    final interests = await repo.loadOfflineInterests();
    final kept = await repo.keptTemplateIds();
    if (!mounted) return;
    setState(() {
      _interests = interests;
      _keptIds = kept;
    });
    await _loadTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    // Community browse/import is Pro-only (access_tiers.md) — never query
    // Supabase's community tables in the background for a Free user, even
    // though the upgrade prompt already hides the resulting list.
    if (!await ref.read(revenueCatProvider).isPro()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(communityRepositoryProvider);
      if (_showKeptOnly) {
        var kept = await repo.keptTemplates();
        if (_selectedCategory != 'all') {
          kept = kept.where((t) => t.category == _selectedCategory).toList();
        }
        if (mounted) {
          setState(() {
            _templates = kept;
            _fromCache = true;
            _fromKept = true;
            _cachedAt = null;
            _keptIds = kept.map((t) => t.supabaseId).toSet();
          });
        }
        return;
      }
      final result = await repo.browseCommunity(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        sortBy: _sortBy,
        interests: _interests,
      );
      final keptIds = await repo.keptTemplateIds();
      if (mounted) {
        setState(() {
          _templates = result.templates;
          _fromCache = result.fromCache;
          _fromKept = result.fromKept;
          _cachedAt = result.fetchedAt;
          _keptIds = keptIds;
        });
      }
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'community_browser_screen: load'));
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleKeep(CommunityTemplate template) async {
    final repo = ref.read(communityRepositoryProvider);
    final id = template.supabaseId;
    final messenger = ScaffoldMessenger.of(context);
    if (_keptIds.contains(id)) {
      await repo.removeKeptTemplate(id);
      if (!mounted) return;
      setState(() => _keptIds = {..._keptIds}..remove(id));
      if (_showKeptOnly) await _loadTemplates();
      return;
    }
    final ok = await repo.keepTemplateOffline(template);
    if (!mounted) return;
    if (ok) {
      setState(() => _keptIds = {..._keptIds, id});
    } else {
      messenger.showSnackBar(const SnackBar(
        content: Text(
            'Need a connection to download this template onto the device'),
      ));
    }
  }

  Future<void> _addInterest(String raw) async {
    final tag = raw.trim();
    if (tag.isEmpty) return;
    if (_interests.any((i) => i.toLowerCase() == tag.toLowerCase())) return;
    final next = [..._interests, tag];
    setState(() => _interests = next);
    await ref.read(communityRepositoryProvider).saveOfflineInterests(next);
    await _loadTemplates();
  }

  Future<void> _removeInterest(String tag) async {
    final next = _interests.where((i) => i != tag).toList();
    setState(() => _interests = next);
    await ref.read(communityRepositoryProvider).saveOfflineInterests(next);
    await _loadTemplates();
  }

  void _showAddInterestDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('On this boat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Only templates that mention these stay in your browse '
                'cache — e.g. Yanmar 4HJ45, not every Volvo Penta share.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Make / model',
                  hintText: 'Yanmar 4HJ45',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (v) {
                  Navigator.of(ctx).pop();
                  _addInterest(v);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final s in BoatEngineTaxonomy.interestSuggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _addInterest(s);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text;
              Navigator.of(ctx).pop();
              _addInterest(v);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _importTemplate(CommunityTemplate template) async {
    final settings = await ref.read(userSettingsProvider.future);
    final boatId = settings?.activeBoatSupabaseId ?? '';

    final ok = await ref
        .read(communityRepositoryProvider)
        .importTemplate(template.supabaseId, boatId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '"${template.title}" imported to your checklists'
            : 'Import failed — try again'),
      ),
    );
  }

  Future<void> _rateTemplate(CommunityTemplate template, int rating) async {
    final ok = await ref
        .read(communityRepositoryProvider)
        .rateTemplate(template.supabaseId, rating);
    if (!mounted) return;
    if (ok) {
      _loadTemplates();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating failed — try again')),
      );
    }
  }

  void _showRateDialog(CommunityTemplate template) async {
    final myRating =
        await ref.read(communityRepositoryProvider).getMyRating(template.supabaseId);
    if (!mounted) return;
    int? selected = myRating;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Rate "${template.title}"'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                icon: Icon(
                  (selected ?? 0) >= star ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setDialogState(() => selected = star),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () {
                      Navigator.of(ctx).pop();
                      _rateTemplate(template, selected!);
                    },
              child: const Text('Rate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportTemplate(
      CommunityTemplate template, String reason, String? note) async {
    final ok = await ref
        .read(communityRepositoryProvider)
        .reportTemplate(template.supabaseId, reason: reason, note: note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Reported — thanks, this will be reviewed.'
            : 'Report failed — try again'),
      ),
    );
  }

  void _showReportDialog(CommunityTemplate template) {
    showDialog<({String reason, String? note})>(
      context: context,
      builder: (_) => _ReportDialog(templateTitle: template.title),
    ).then((result) {
      if (result != null) _reportTemplate(template, result.reason, result.note);
    });
  }

  /// Diffs [localGroup]'s current items against [template]'s newer content
  /// and, after an explicit confirm showing exactly what will change, applies
  /// a non-destructive merge: new items added, matched items' text refreshed
  /// but local state (completion/notes/photos) kept, everything else left
  /// alone entirely (per product decision — never replaces, never deletes).
  Future<void> _showUpdateDialog(
      ChecklistGroup localGroup, CommunityTemplate template) async {
    final localItems = await ref
        .read(checklistRepositoryProvider)
        .getItemsByGroup(localGroup.supabaseId);
    final parsed = jsonDecode(template.content) as Map<String, dynamic>;
    final diff = computeCommunityMergeDiff(
      localItems: localItems,
      parsedContent: parsed,
      groupSupabaseId: localGroup.supabaseId,
      boatSupabaseId: localGroup.boatSupabaseId,
    );

    if (!mounted) return;
    if (diff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already up to date')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update "${localGroup.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${diff.toAdd.length} new item(s) will be added.'),
            Text(
                '${diff.toUpdate.length} existing item(s) will be merged — '
                'their text updates, but your completed status, notes, and '
                'photos are kept.'),
            Text('${diff.keptCount} of your item(s) are kept as-is.'),
            const SizedBox(height: 12),
            const Text(
              'Nothing is replaced or deleted — this only adds and merges.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final settings = await ref.read(userSettingsProvider.future);
              final boatId = settings?.activeBoatSupabaseId ?? '';
              final ok = await ref
                  .read(communityRepositoryProvider)
                  .applyCommunityUpdate(localGroup: localGroup, boatId: boatId);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? '"${localGroup.title}" updated'
                      : 'Update failed — try again'),
                ),
              );
            },
            child: const Text('Merge Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final myGroupsAsync = ref.watch(checklistGroupsProvider(null));
    final importedByTemplateId = <String, ChecklistGroup>{
      for (final g in myGroupsAsync.asData?.value ?? const <ChecklistGroup>[])
        if (g.communityTemplateId != null) g.communityTemplateId!: g,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TitleTile(
              title: 'Community Library',
            ),
            Expanded(
              child: isProAsync.when(
                data: (isPro) => isPro
                    ? _buildProBody(importedByTemplateId)
                    : _buildUpgradePrompt(),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isProAsync.maybeWhen(
        data: (isPro) => isPro
            ? FloatingActionButton(
                onPressed: _pickListToShare,
                tooltip: 'Share one of your lists',
                child: const Icon(Icons.upload),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildProBody(Map<String, ChecklistGroup> importedByTemplateId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Category',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(_categoryLabel(cat)),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value!);
              _loadTemplates();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'On this boat',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              for (final tag in _interests)
                InputChip(
                  label: Text(tag),
                  onDeleted: () => _removeInterest(tag),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text(_interests.isEmpty ? 'Add make / model' : 'Add'),
                onPressed: _showAddInterestDialog,
              ),
              FilterChip(
                label: const Text('On this device'),
                selected: _showKeptOnly,
                onSelected: (v) {
                  setState(() => _showKeptOnly = v);
                  _loadTemplates();
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<CommunitySortOrder>(
              segments: const [
                ButtonSegment(
                  value: CommunitySortOrder.recent,
                  label: Text('Recent'),
                  icon: Icon(Icons.schedule, size: 16),
                ),
                ButtonSegment(
                  value: CommunitySortOrder.mostDownloaded,
                  label: Text('Most Downloaded'),
                  icon: Icon(Icons.trending_up, size: 16),
                ),
              ],
              selected: {_sortBy},
              onSelectionChanged: (selection) {
                setState(() => _sortBy = selection.first);
                _loadTemplates();
              },
            ),
          ),
        ),
        if (_fromCache)
          _OfflineCacheBanner(
            fromKept: _fromKept,
            cachedAt: _cachedAt,
          ),
        Expanded(child: _buildList(importedByTemplateId)),
      ],
    );
  }

  Widget _buildList(Map<String, ChecklistGroup> importedByTemplateId) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load templates: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTemplates,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final query = _searchController.text.toLowerCase();
    final filtered = _templates.where((t) {
      if (query.isEmpty) return true;
      return t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No community templates found.\nBe the first to publish!',
            textAlign: TextAlign.center),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final template = filtered[index];
          final importedGroup = importedByTemplateId[template.supabaseId];
          final updateAvailable = importedGroup != null &&
              (importedGroup.communityTemplateVersion ?? 1) < template.version;
          return _TemplateCard(
            template: template,
            kept: _keptIds.contains(template.supabaseId),
            onKeep: () => _toggleKeep(template),
            onImport: () => _importTemplate(template),
            onRate: () => _showRateDialog(template),
            onReport: () => _showReportDialog(template),
            updateAvailable: updateAvailable,
            onUpdate: updateAvailable
                ? () => _showUpdateDialog(importedGroup, template)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Community Library is Pro only',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Browse, import, and publish checklists shared by other sailors.\n\nUpgrade to Pro to unlock.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  RevenueCatService().showPaywall(context),
              child: const Text('Upgrade to Pro'),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 1 of publishing: pick one of the user's own checklist/maintenance/
  /// safety lists to share — replaces the old blank-form dialog, which always
  /// published an empty `items: []` template regardless of what was typed.
  /// Picking a list already linked to a template the user authored (S5)
  /// republishes/updates it instead of creating a duplicate.
  void _pickListToShare() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (sheetContext, scrollController) => Consumer(
          builder: (sheetContext, ref, _) {
            final asyncGroups = ref.watch(checklistGroupsProvider(null));
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Choose a list to share',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: asyncGroups.when(
                    data: (groups) {
                      if (groups.isEmpty) {
                        return const Center(
                          child: Text('You have no lists yet.'),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final alreadyPublished =
                              group.communityTemplateId != null &&
                                  group.origin != 'community';
                          return ListTile(
                            leading: Icon(_appTypeIcon(group.appType)),
                            title: Text(group.title),
                            subtitle: Text(alreadyPublished
                                ? '${_categoryLabel(group.appType)} · already published — tap to update'
                                : _categoryLabel(group.appType)),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _showPublishConfirmDialog(group);
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static IconData _appTypeIcon(String appType) => switch (appType) {
        'maintenance' => Icons.build,
        'safety' => Icons.shield,
        _ => Icons.checklist,
      };

  /// Step 2: confirm description + engine/boat tag, then serialize the
  /// group's real items ([CommunityTemplate.fromChecklistGroup]) and publish
  /// — or, if this group was already published by this user, republish
  /// (update) the same template row instead of creating a duplicate.
  Future<void> _showPublishConfirmDialog(ChecklistGroup group) async {
    final isUpdate =
        group.communityTemplateId != null && group.origin != 'community';
    CommunityTemplate? cached;
    if (isUpdate) {
      cached = await ref
          .read(communityRepositoryProvider)
          .getCachedTemplate(group.communityTemplateId!);
    }
    if (!mounted) return;

    final descCtrl = TextEditingController(text: cached?.description ?? '');
    String? selectedEngine =
        (cached?.subcategory.isNotEmpty ?? false) ? cached!.subcategory : null;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              isUpdate ? 'Update "${group.title}"' : 'Share "${group.title}"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(_categoryLabel(group.appType))),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedEngine,
                  decoration: const InputDecoration(
                    labelText: 'Engine/Boat (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...BoatEngineTaxonomy.makes.map(
                      (make) =>
                          DropdownMenuItem(value: make, child: Text(make)),
                    ),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedEngine = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _publish(
                  group: group,
                  description: descCtrl.text.trim(),
                  subcategory: selectedEngine ?? '',
                  isUpdate: isUpdate,
                );
              },
              child: Text(isUpdate ? 'Update' : 'Publish'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish({
    required ChecklistGroup group,
    required String description,
    required String subcategory,
    required bool isUpdate,
  }) async {
    final items = await ref
        .read(checklistRepositoryProvider)
        .getItemsByGroup(group.supabaseId);
    final settings = await ref.read(userSettingsProvider.future);

    final template = CommunityTemplate.fromChecklistGroup(
      group: group,
      items: items,
      description: description,
      subcategory: subcategory,
      authorId: settings?.userId ?? '',
    );

    final repo = ref.read(communityRepositoryProvider);
    final CommunityTemplate saved;
    if (isUpdate) {
      template.supabaseId = group.communityTemplateId!;
      saved = await repo.updateTemplate(template);
    } else {
      saved = await repo.publishTemplate(template);
    }

    if (!mounted) return;
    final ok = saved.supabaseId.isNotEmpty;
    if (ok) {
      await repo.linkGroupToTemplate(
        groupSupabaseId: group.supabaseId,
        templateId: saved.supabaseId,
        version: saved.version,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (isUpdate
                ? '"${saved.title}" updated (v${saved.version})'
                : '"${saved.title}" shared with the community')
            : '${isUpdate ? 'Update' : 'Publish'} failed — try again'),
      ),
    );
    _loadTemplates();
  }
}

/// #321 — reason + optional note for flagging a template, returned via
/// `Navigator.pop(context, (reason: ..., note: ...))` on submit, `null` on
/// cancel. A dedicated [StatefulWidget] (not an inline `StatefulBuilder` +
/// externally-owned controller) so the [TextEditingController] is disposed
/// by this widget's own `dispose()` — tied to the dialog route's actual
/// unmount, after any exit transition finishes, rather than racing a
/// `Future.then` callback against a still-rendering frame.
class _ReportDialog extends StatefulWidget {
  final String templateTitle;
  const _ReportDialog({required this.templateTitle});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  /// Kept short and generic; there's no in-app moderation queue yet, a
  /// human reviews reported rows directly for now.
  static const _reasons = [
    'Incorrect or unsafe content',
    'Inappropriate',
    'Duplicate of another template',
    'Other',
  ];

  String _reason = _reasons.first;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report "${widget.templateTitle}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: [
              for (final r in _reasons) DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (v) => setState(() => _reason = v ?? _reasons.first),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop((
            reason: _reason,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          )),
          child: const Text('Report'),
        ),
      ],
    );
  }
}

class _OfflineCacheBanner extends StatelessWidget {
  final bool fromKept;
  final DateTime? cachedAt;
  const _OfflineCacheBanner({required this.fromKept, this.cachedAt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final when = cachedAt?.toLocal().toString().split('.').first;
    final text = fromKept
        ? 'Offline — showing templates you kept on this device.'
        : (when == null
            ? 'Offline — showing saved results. Pull to refresh when back online.'
            : 'Offline — showing saved results from $when. Pull to refresh when back online.');
    return Material(
      color: SisuColors.getListSurface(isDark),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Icon(Icons.cloud_off,
                size: 16, color: SisuColors.getTextSecondaryColor(isDark)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: SisuColors.getTextSecondaryColor(isDark),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final CommunityTemplate template;
  final bool kept;
  final VoidCallback onKeep;
  final VoidCallback onImport;
  final VoidCallback onRate;
  final VoidCallback onReport;
  final bool updateAvailable;
  final VoidCallback? onUpdate;

  const _TemplateCard({
    required this.template,
    required this.kept,
    required this.onKeep,
    required this.onImport,
    required this.onRate,
    required this.onReport,
    required this.updateAvailable,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    template.category.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (template.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                template.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            InkWell(
              onTap: onRate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(5, (i) {
                    final filled = template.ratingCount > 0 &&
                        template.avgRating >= i + 1 - 0.5;
                    return Icon(filled ? Icons.star : Icons.star_border,
                        size: 16, color: Colors.amber);
                  }),
                  const SizedBox(width: 4),
                  Text(
                    template.ratingCount > 0
                        ? '${template.avgRating.toStringAsFixed(1)} (${template.ratingCount})'
                        : 'Rate this',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (template.subcategory.isNotEmpty)
                  Chip(
                    label: Text(template.subcategory,
                        style: const TextStyle(fontSize: 11)),
                    avatar: const Icon(Icons.directions_boat, size: 14),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  label: Text('${template.downloadCount} downloads',
                      style: const TextStyle(fontSize: 11)),
                  avatar: const Icon(Icons.download, size: 14),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                if (updateAvailable)
                  Chip(
                    label: const Text('Update available',
                        style: TextStyle(fontSize: 11)),
                    avatar: const Icon(Icons.new_releases, size: 14),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.amber.shade100,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // #321 — low-emphasis, doesn't compete with Update/Import.
                IconButton(
                  onPressed: onKeep,
                  icon: Icon(
                    kept ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                  ),
                  tooltip: kept
                      ? 'Remove from this device'
                      : 'Keep on this device',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  tooltip: 'Report this template',
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                if (updateAvailable) ...[
                  OutlinedButton.icon(
                    onPressed: onUpdate,
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Update'),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
