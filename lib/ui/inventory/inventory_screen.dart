import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/title_tile.dart';
import '../components/themed_state_tile.dart';
import '../components/main_list_tile.dart';
import '../../core/colors.dart';
import '../components/common_drawer.dart';
import '../components/import_export.dart';
import '../components/record_detail_screen.dart';
import '../components/photo_source_picker.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../../services/revenuecat_service.dart';
import '../../services/record_share_service.dart';
import '../../services/import_service.dart';
import '../../services/inventory_reorder_service.dart';
import '../../providers/checklist_provider.dart';

final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  return ref.watch(inventoryItemRepositoryProvider).watchInventoryItems();
});

const _noMaintLink = 'None';

String _formatQuantity(InventoryItem item) {
  final qty = item.quantity == item.quantity.roundToDouble()
      ? item.quantity.toInt().toString()
      : item.quantity.toString();
  final unit = item.unit != null && item.unit!.isNotEmpty ? ' ${item.unit}' : '';
  return '$qty$unit';
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _selecting = false;
  final Set<int> _selectedIds = {};
  final _searchCtrl = TextEditingController();
  String _search = '';
  // #318 — location-tree filter (InventoryReorderService.locationTree was
  // already implemented and tested but never wired into any UI).
  String? _locationFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle(int id) => setState(() {
        if (!_selectedIds.remove(id)) _selectedIds.add(id);
      });

  void _exitSelection() => setState(() {
        _selecting = false;
        _selectedIds.clear();
      });

  Future<void> _shareSelected(List<InventoryItem> all) async {
    final selected =
        all.where((i) => _selectedIds.contains(i.id)).toList();
    final messenger = ScaffoldMessenger.of(context);
    if (selected.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Select at least one item')));
      return;
    }
    await RecordShareService.shareInventory(selected);
    if (mounted) _exitSelection();
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final isPro = isProAsync.value ?? false;
    final allItems = itemsAsync.value ?? const <InventoryItem>[];
    final maintItems = ref
            .watch(checklistItemsForAppTypeProvider('maintenance'))
            .asData
            ?.value ??
        const <ChecklistItem>[];
    final maintGroups =
        ref.watch(checklistGroupsProvider('maintenance')).asData?.value ??
            const <ChecklistGroup>[];

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: _selecting
                    ? '${_selectedIds.length} selected'
                    : 'Inventory',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                actionsBuilder: (color) => _selecting
                    ? [
                        IconButton(
                          icon: Icon(Icons.share, color: color),
                          tooltip: 'Share selected',
                          onPressed: () => _shareSelected(allItems),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: color),
                          tooltip: 'Cancel',
                          onPressed: _exitSelection,
                        ),
                      ]
                    : [
                        // Standard trailing order (right→left): menu,
                        // import/export, share — so share renders first.
                        if (isPro && allItems.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.ios_share, color: color),
                            tooltip: 'Select to share',
                            onPressed: () => setState(() => _selecting = true),
                          ),
                        IconButton(
                          icon: Icon(Icons.import_export, color: color),
                          tooltip: 'Import / Export',
                          onPressed: () => showImportExportSheet(
                            context,
                            ModuleImportExport(
                              kind: ImportService.kindInventory,
                              label: 'Inventory',
                              fileBaseName: 'sisu_inventory',
                              exportCurrent: () async =>
                                  ImportService.exportInventory(
                                    allItems,
                                    unitSystem: ref.read(unitSystemProvider),
                                  ),
                              existingNames: () async =>
                                  allItems.map((e) => e.name).toList(),
                              persist: (batch) async {
                                final repo =
                                    ref.read(inventoryItemRepositoryProvider);
                                final existing =
                                    await repo.watchInventoryItems().first;
                                var inserted = 0;
                                var updated = 0;
                                for (final it in batch.inventoryItems) {
                                  final match = ImportService.matchExisting(
                                    existing: existing,
                                    incomingId: it.supabaseId,
                                    idOf: (e) => e.supabaseId,
                                    contentKeyOf:
                                        ImportService.contentKeyInventory,
                                    incomingContentKey:
                                        ImportService.contentKeyInventory(it),
                                  );
                                  if (match != null) {
                                    it.supabaseId = match.supabaseId;
                                    it.id = match.id;
                                    await repo.updateInventoryItem(it);
                                    updated++;
                                  } else {
                                    await repo.addInventoryItem(it);
                                    existing.add(it);
                                    inserted++;
                                  }
                                }
                                return ImportPersistResult(
                                    inserted: inserted, updated: updated);
                              },
                            ),
                            isPro: isPro,
                            onProRequired: () =>
                                _showProRequiredDialog(context),
                            ref: ref,
                          ),
                        ),
                      ],
              ),
              if (!_selecting)
                MainListSearchBar(
                  controller: _searchCtrl,
                  hintText: 'Search inventory...',
                  onChanged: (v) => setState(() => _search = v),
                ),
              if (!_selecting)
                _LocationFilterRow(
                  locations: InventoryReorderService.locationTree(allItems),
                  selected: _locationFilter,
                  onSelected: (loc) => setState(() => _locationFilter = loc),
                ),
              Expanded(
                child: itemsAsync.when(
                  data: (items) {
                    final searched = items.where((it) {
                      if (_search.isEmpty) return true;
                      final q = _search.toLowerCase();
                      return it.name.toLowerCase().contains(q) ||
                          (it.location?.toLowerCase().contains(q) ?? false) ||
                          (it.serialNumber?.toLowerCase().contains(q) ?? false) ||
                          (it.barcode?.toLowerCase().contains(q) ?? false);
                    });
                    final filtered = InventoryReorderService.filterByLocation(
                        searched, _locationFilter);
                    if (filtered.isEmpty) {
                      return Center(
                          child: Text(items.isEmpty
                              ? 'No inventory items yet'
                              : 'No matches'));
                    }
                    if (_selecting) {
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final item = filtered[i];
                          return ThemedStateTile(
                            state: ItemListState.defaults,
                            leading: Checkbox(
                              value: _selectedIds.contains(item.id),
                              onChanged: (_) => _toggle(item.id),
                            ),
                            title: item.name,
                            subtitle: 'Qty: ${_formatQuantity(item)}',
                            onTap: () => _toggle(item.id),
                          );
                        },
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        return MainListTile(
                          onTap: () => _showDetail(
                              context, ref, item, isPro, maintItems, maintGroups),
                          header: MainListTile.iconHeader(
                            icon: Icons.inventory_2_outlined,
                            iconColor: Colors.brown,
                          ),
                          title: item.name,
                          tags: [
                            if (item.location != null &&
                                item.location!.isNotEmpty)
                              item.location!,
                          ],
                          tagColor: Colors.brown,
                          countLine: 'Qty: ${_formatQuantity(item)}',
                          metaLine: (item.serialNumber != null &&
                                  item.serialNumber!.isNotEmpty)
                              ? 'S/N ${item.serialNumber}'
                              : null,
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
          ),
        ),
      ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              onPressed: () => isPro
                  ? _showAddEditDialog(
                      context, ref, allItems, maintItems, maintGroups)
                  : _showProRequiredDialog(context),
              child: const Icon(Icons.add),
            ),
      endDrawer: _buildEndDrawer(),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) => Column(
            children: [
              DrawerHeaderWidget(title: 'Menu'),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Divider(),
                      SectionHeader(title: 'Account'),
                      AccountSection(),
                      const Divider(),
                      SectionHeader(title: 'Data Management'),
                      DataManagementSection(),
                      ProUpgradeSection(),
                      AboutSection(),
                    ],
                  ),
                ),
              ),
              DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _showProRequiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sisu Mate Pro Required'),
        content: const Text(
            'Adding and editing inventory items is a Pro feature. Upgrade to unlock inventory management.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              RevenueCatService().showPaywall(context);
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    bool isPro,
    List<ChecklistItem> maintItems,
    List<ChecklistGroup> maintGroups,
  ) {
    final items =
        ref.read(inventoryItemsProvider).asData?.value ?? [item];
    final index = items.indexWhere((m) => m.supabaseId == item.supabaseId);
    final list = index < 0 ? [item] : items;
    final start = index < 0 ? 0 : index;
    String groupTitleOf(String groupId) =>
        maintGroups.where((g) => g.supabaseId == groupId).firstOrNull?.title ??
        '';
    final usedByOptions = [
      _noMaintLink,
      ...maintItems.map(
        (c) => InventoryReorderService.maintenanceItemLabel(
          c,
          groupTitleOf: groupTitleOf,
        ),
      ),
    ];
    String usedByLabelFor(InventoryItem m) =>
        InventoryReorderService.usedByLabel(
          m,
          maintItems,
          groupTitleOf: groupTitleOf,
        ) ??
        _noMaintLink;

    context.push(
      AppRoutes.inventoryDetail,
      extra: RecordDetailArgs(
          itemCount: list.length,
          initialIndex: start,
          canEdit: isPro,
          titleForIndex: (i) => list[i].name,
          photoPathForIndex: (i) => list[i].localPath,
          historyForIndex: (i) =>
              InventoryReorderService.quantityHistoryLines(list[i]),
          fieldsForIndex: (i) {
            final m = list[i];
            return [
              RecordField(key: 'name', label: 'Name', value: m.name),
              RecordField(
                  key: 'quantity',
                  label: 'Quantity',
                  value: m.quantity.toString(),
                  isNumber: true),
              RecordField(key: 'unit', label: 'Unit', value: m.unit ?? ''),
              RecordField(
                  key: 'location', label: 'Location', value: m.location ?? ''),
              RecordField(
                  key: 'serialNumber',
                  label: 'Serial number',
                  value: m.serialNumber ?? ''),
              RecordField(
                  key: 'barcode',
                  label: 'Barcode',
                  value: m.barcode ?? ''),
              RecordField(
                  key: 'usedBy',
                  label: 'Used by',
                  value: usedByLabelFor(m),
                  options: usedByOptions),
              RecordField(
                  key: 'notes',
                  label: 'Notes',
                  value: m.notes ?? '',
                  multiline: true),
              RecordField(
                  key: 'lastModified',
                  label: 'Last modified',
                  value: m.lastModified.toIso8601String()),
            ];
          },
          onSave: (i, values) async {
            final m = list[i];
            final usedBy = values['usedBy'];
            String? linkedId;
            if (usedBy != null && usedBy != _noMaintLink) {
              for (final c in maintItems) {
                final label = InventoryReorderService.maintenanceItemLabel(
                  c,
                  groupTitleOf: groupTitleOf,
                );
                if (label == usedBy) {
                  linkedId = c.supabaseId;
                  break;
                }
              }
            }
            m
              ..name = values['name'] ?? m.name
              ..quantity =
                  double.tryParse(values['quantity'] ?? '') ?? m.quantity
              ..unit = (values['unit'] ?? '').isEmpty ? null : values['unit']
              ..location =
                  (values['location'] ?? '').isEmpty ? null : values['location']
              ..serialNumber = (values['serialNumber'] ?? '').isEmpty
                  ? null
                  : values['serialNumber']
              ..barcode =
                  (values['barcode'] ?? '').isEmpty ? null : values['barcode']
              ..linkedMaintenanceItemSupabaseId = linkedId
              ..notes = (values['notes'] ?? '').isEmpty ? null : values['notes'];
            await ref
                .read(inventoryItemRepositoryProvider)
                .updateInventoryItem(m);
          },
          onDelete: isPro
              ? (i) => ref
                  .read(inventoryItemRepositoryProvider)
                  .deleteInventoryItem(list[i])
              : null,
          onPhotoChanged: isPro
              ? (i, path) async {
                  list[i].localPath = path;
                  await ref
                      .read(inventoryItemRepositoryProvider)
                      .updateInventoryItem(list[i]);
                }
              : null,
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref,
    List<InventoryItem> allItems,
    List<ChecklistItem> maintItems,
    List<ChecklistGroup> maintGroups, {
    InventoryItem? existing,
  }) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AddEditInventoryItemDialog(
        existing: existing,
        // #318 — barcode-collision check on scan (add flow only) needs to
        // see what's already on hand.
        existingItems: allItems,
        maintenanceItems: maintItems,
        maintenanceGroups: maintGroups,
        onSave: (item) async {
          final repo = ref.read(inventoryItemRepositoryProvider);
          if (existing == null) {
            await repo.addInventoryItem(item);
          } else {
            await repo.updateInventoryItem(item);
          }
          navigator.pop();
          messenger
              .showSnackBar(SnackBar(content: Text('${item.name} saved')));
        },
        onOpenExisting: (match) {
          navigator.pop();
          _showAddEditDialog(
            context,
            ref,
            allItems,
            maintItems,
            maintGroups,
            existing: match,
          );
        },
      ),
    );
  }
}

/// #318 — location-tree filter row (only shown once there's more than one
/// distinct location to filter by; a single-location boat gains nothing
/// from it). Matches Shopping's horizontal `FilterChip` row pattern.
class _LocationFilterRow extends StatelessWidget {
  final List<String> locations;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _LocationFilterRow({
    required this.locations,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.length < 2) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final loc in locations)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(loc),
                selected: selected == loc,
                onSelected: (isSelected) =>
                    onSelected(isSelected ? loc : null),
              ),
            ),
        ],
      ),
    );
  }
}

class AddEditInventoryItemDialog extends StatefulWidget {
  final InventoryItem? existing;
  final void Function(InventoryItem) onSave;
  /// #318 — items already on hand, for the barcode-scan duplicate check
  /// (add flow only; empty/irrelevant when editing).
  final List<InventoryItem> existingItems;
  /// #319 — maintenance checklist items this spare can be linked to.
  final List<ChecklistItem> maintenanceItems;
  final List<ChecklistGroup> maintenanceGroups;
  /// Called instead of [onSave] when a scanned barcode matches an existing
  /// item and the user chooses to open it rather than add a duplicate.
  final ValueChanged<InventoryItem>? onOpenExisting;
  const AddEditInventoryItemDialog({
    super.key,
    this.existing,
    required this.onSave,
    this.existingItems = const [],
    this.maintenanceItems = const [],
    this.maintenanceGroups = const [],
    this.onOpenExisting,
  });

  @override
  State<AddEditInventoryItemDialog> createState() =>
      AddEditInventoryItemDialogState();
}

class AddEditInventoryItemDialogState
    extends State<AddEditInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _localPath;
  String? _linkedMaintenanceItemSupabaseId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _locationCtrl.text = existing.location ?? '';
      _quantityCtrl.text = existing.quantity == existing.quantity.roundToDouble()
          ? existing.quantity.toInt().toString()
          : existing.quantity.toString();
      _unitCtrl.text = existing.unit ?? '';
      _serialCtrl.text = existing.serialNumber ?? '';
      _barcodeCtrl.text = existing.barcode ?? '';
      _notesCtrl.text = existing.notes ?? '';
      _localPath = existing.localPath;
      _linkedMaintenanceItemSupabaseId =
          existing.linkedMaintenanceItemSupabaseId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    _serialCtrl.dispose();
    _barcodeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _attachPhoto() async {
    final picked = await pickPhotoFromCameraOrGallery(context);
    if (picked != null) setState(() => _localPath = picked.path);
  }

  /// #318 — scan a barcode into the field; if it already belongs to an
  /// on-hand item (add flow only — editing an item doesn't collide with
  /// itself), offer to open that item instead of risking a duplicate.
  Future<void> _scanBarcode() async {
    final result = await context.push<String>(AppRoutes.barcodeScanner);
    if (result == null || !mounted) return;

    final isAdding = widget.existing == null;
    final match = isAdding
        ? InventoryReorderService.findByBarcode(widget.existingItems, result)
        : null;

    if (match != null) {
      final openExisting = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Already in inventory'),
          content: Text(
              'This barcode is already on "${match.name}" (qty '
              '${_formatQuantity(match)}). Open that item instead of '
              'adding a new one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Add anyway'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open existing'),
            ),
          ],
        ),
      );
      if (openExisting == true) {
        widget.onOpenExisting?.call(match);
        return;
      }
    }
    if (mounted) setState(() => _barcodeCtrl.text = result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Inventory Item' : 'Add Inventory Item'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          return double.tryParse(v) == null
                              ? 'Invalid number'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _serialCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Serial number'),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Barcode'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Scan barcode',
                      onPressed: _scanBarcode,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.maintenanceItems.isNotEmpty ||
                    _linkedMaintenanceItemSupabaseId != null) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: _linkedMaintenanceItemSupabaseId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Used by'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text(_noMaintLink)),
                      for (final c in widget.maintenanceItems)
                        DropdownMenuItem(
                          value: c.supabaseId,
                          child: Text(
                            InventoryReorderService.maintenanceItemLabel(
                              c,
                              groupTitleOf: (id) => widget.maintenanceGroups
                                      .where((g) => g.supabaseId == id)
                                      .firstOrNull
                                      ?.title ??
                                  '',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (_linkedMaintenanceItemSupabaseId != null &&
                          !widget.maintenanceItems.any((c) =>
                              c.supabaseId ==
                              _linkedMaintenanceItemSupabaseId))
                        DropdownMenuItem(
                          value: _linkedMaintenanceItemSupabaseId,
                          child: const Text('Linked task missing'),
                        ),
                    ],
                    onChanged: (v) => setState(
                        () => _linkedMaintenanceItemSupabaseId = v),
                  ),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                if (_localPath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(File(_localPath!),
                              width: 48, height: 48, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Photo attached')),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _localPath = null),
                        ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  onPressed: _attachPhoto,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(
                      _localPath == null ? 'Add photo' : 'Change photo'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = widget.existing ??
        (InventoryItem()
          ..supabaseId = 'inv_${DateTime.now().millisecondsSinceEpoch}'
          ..boatSupabaseId = '00000000-0000-0000-0000-000000000000');
    item
      ..name = _nameCtrl.text
      ..location = _locationCtrl.text.isEmpty ? null : _locationCtrl.text
      ..quantity = double.tryParse(_quantityCtrl.text) ?? 1
      ..unit = _unitCtrl.text.isEmpty ? null : _unitCtrl.text
      ..serialNumber = _serialCtrl.text.isEmpty ? null : _serialCtrl.text
      ..barcode = _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text
      ..linkedMaintenanceItemSupabaseId = _linkedMaintenanceItemSupabaseId
      ..notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text
      ..localPath = _localPath;
    widget.onSave(item);
  }
}
