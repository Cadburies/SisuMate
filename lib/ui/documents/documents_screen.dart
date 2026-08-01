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
import '../../models/models.dart';
import '../../services/revenuecat_service.dart';
import '../../services/record_share_service.dart';
import '../../services/import_service.dart';

final documentsProvider = StreamProvider<List<Document>>((ref) {
  return ref.watch(documentRepositoryProvider).watchDocuments();
});

const _documentTypes = [
  'Registration',
  'Insurance',
  'License',
  'Manual',
  'Warranty',
  'Other',
];

IconData _iconForType(String type) {
  switch (type) {
    case 'Registration':
      return Icons.directions_boat_outlined;
    case 'Insurance':
      return Icons.shield_outlined;
    case 'License':
      return Icons.badge_outlined;
    case 'Manual':
      return Icons.menu_book_outlined;
    case 'Warranty':
      return Icons.receipt_long_outlined;
    default:
      return Icons.description_outlined;
  }
}

String _formatDate(DateTime d) => d.toString().split(' ')[0];

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  bool _selecting = false;
  final Set<int> _selectedIds = {};
  final _searchCtrl = TextEditingController();
  String _search = '';

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

  Future<void> _shareSelected(List<Document> all) async {
    final selected =
        all.where((d) => _selectedIds.contains(d.id)).toList();
    final messenger = ScaffoldMessenger.of(context);
    if (selected.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Select at least one document')));
      return;
    }
    await RecordShareService.shareDocuments(selected);
    if (mounted) _exitSelection();
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final documentsAsync = ref.watch(documentsProvider);
    final isPro = isProAsync.value ?? false;
    final documents = documentsAsync.value ?? const <Document>[];

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: _selecting
                    ? '${_selectedIds.length} selected'
                    : 'Documents Vault',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                actionsBuilder: (color) => _selecting
                    ? [
                        IconButton(
                          icon: Icon(Icons.share, color: color),
                          tooltip: 'Share selected',
                          onPressed: () => _shareSelected(documents),
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
                        if (isPro && documents.isNotEmpty)
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
                              kind: ImportService.kindDocument,
                              label: 'Documents',
                              fileBaseName: 'sisu_documents',
                              exportCurrent: () async =>
                                  ImportService.exportDocuments(documents),
                              existingNames: () async =>
                                  documents.map((e) => e.title).toList(),
                              persist: (batch) async {
                                final repo =
                                    ref.read(documentRepositoryProvider);
                                final existing =
                                    await repo.watchDocuments().first;
                                var inserted = 0;
                                var updated = 0;
                                for (final d in batch.documents) {
                                  final match = ImportService.matchExisting(
                                    existing: existing,
                                    incomingId: d.supabaseId,
                                    idOf: (e) => e.supabaseId,
                                    contentKeyOf:
                                        ImportService.contentKeyDocument,
                                    incomingContentKey:
                                        ImportService.contentKeyDocument(d),
                                  );
                                  if (match != null) {
                                    d.supabaseId = match.supabaseId;
                                    d.id = match.id;
                                    await repo.updateDocument(d);
                                    updated++;
                                  } else {
                                    await repo.addDocument(d);
                                    existing.add(d);
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
                  hintText: 'Search documents...',
                  onChanged: (v) => setState(() => _search = v),
                ),
              Expanded(
                child: documentsAsync.when(
                  data: (documents) {
                    final filtered = documents.where((d) {
                      if (_search.isEmpty) return true;
                      final q = _search.toLowerCase();
                      return d.title.toLowerCase().contains(q) ||
                          d.type.toLowerCase().contains(q);
                    }).toList();
                    if (filtered.isEmpty) {
                      return Center(
                          child: Text(documents.isEmpty
                              ? 'No documents yet'
                              : 'No matches'));
                    }
                    if (_selecting) {
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final document = filtered[i];
                          return ThemedStateTile(
                            state: ItemListState.defaults,
                            leading: Checkbox(
                              value: _selectedIds.contains(document.id),
                              onChanged: (_) => _toggle(document.id),
                            ),
                            title: document.title,
                            subtitle: document.type,
                            onTap: () => _toggle(document.id),
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
                        final document = filtered[i];
                        final expiry = document.expiry;
                        String? attention;
                        if (expiry != null) {
                          final daysLeft =
                              expiry.difference(DateTime.now()).inDays;
                          if (daysLeft < 0) {
                            attention = 'Expired ${_formatDate(expiry)}';
                          } else if (daysLeft <= 30) {
                            attention = 'Expires in $daysLeft days';
                          }
                        }
                        return MainListTile(
                          onTap: () =>
                              _showDetail(context, ref, document, isPro),
                          header: MainListTile.iconHeader(
                            icon: _iconForType(document.type),
                            iconColor: Colors.indigo,
                          ),
                          title: document.title,
                          tags: [document.type],
                          tagColor: Colors.indigo,
                          metaLine: expiry != null
                              ? 'Expires ${_formatDate(expiry)}'
                              : null,
                          attentionLine: attention,
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
                  ? _showAddEditDialog(context, ref)
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
              const Divider(),
              SectionHeader(title: 'Account'),
              AccountSection(),
              const Divider(),
              SectionHeader(title: 'Data Management'),
              DataManagementSection(),
              ProUpgradeSection(),
              AboutSection(),
              const Spacer(),
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
            'Adding and editing documents is a Pro feature. Upgrade to unlock the Documents Vault.'),
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
      BuildContext context, WidgetRef ref, Document document, bool isPro) {
    final docs = ref.read(documentsProvider).asData?.value ?? [document];
    final index = docs.indexWhere((d) => d.supabaseId == document.supabaseId);
    final list = index < 0 ? [document] : docs;
    final start = index < 0 ? 0 : index;

    context.push(
      AppRoutes.documentsDetail,
      extra: RecordDetailArgs(
          itemCount: list.length,
          initialIndex: start,
          canEdit: isPro,
          titleForIndex: (i) => list[i].title,
          photoPathForIndex: (i) => list[i].localPath,
          historyForIndex: (i) {
            final d = list[i];
            final lines = <String>[
              'Last modified: ${d.lastModified.toLocal()}',
            ];
            if (d.expiry != null) {
              lines.add('Expires: ${_formatDate(d.expiry!)}');
            }
            return lines;
          },
          fieldsForIndex: (i) {
            final d = list[i];
            return [
              RecordField(key: 'title', label: 'Title', value: d.title),
              RecordField(
                  key: 'type',
                  label: 'Type',
                  value: d.type,
                  options: _documentTypes),
              RecordField(
                  key: 'expiry',
                  label: 'Expiry',
                  value: d.expiry?.toIso8601String() ?? '',
                  isDate: true),
              RecordField(
                  key: 'notes',
                  label: 'Notes',
                  value: d.notes ?? '',
                  multiline: true),
              RecordField(
                  key: 'lastModified',
                  label: 'Last modified',
                  value: d.lastModified.toIso8601String()),
            ];
          },
          onSave: (i, values) async {
            final d = list[i];
            d
              ..title = values['title'] ?? d.title
              ..type = values['type'] ?? d.type
              ..notes = (values['notes'] ?? '').isEmpty ? null : values['notes']
              ..expiry = (values['expiry'] ?? '').isEmpty
                  ? null
                  : DateTime.tryParse(values['expiry']!);
            await ref.read(documentRepositoryProvider).updateDocument(d);
          },
          onDelete: isPro
              ? (i) =>
                  ref.read(documentRepositoryProvider).deleteDocument(list[i])
              : null,
          onPhotoChanged: isPro
              ? (i, path) async {
                  list[i].localPath = path;
                  await ref
                      .read(documentRepositoryProvider)
                      .updateDocument(list[i]);
                }
              : null,
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {Document? existing}) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AddEditDocumentDialog(
        existing: existing,
        onSave: (document) async {
          final repo = ref.read(documentRepositoryProvider);
          if (existing == null) {
            await repo.addDocument(document);
          } else {
            await repo.updateDocument(document);
          }
          navigator.pop();
          messenger.showSnackBar(
              SnackBar(content: Text('${document.title} saved')));
        },
      ),
    );
  }
}

class AddEditDocumentDialog extends StatefulWidget {
  final Document? existing;
  final void Function(Document) onSave;
  const AddEditDocumentDialog({super.key, this.existing, required this.onSave});

  @override
  State<AddEditDocumentDialog> createState() =>
      AddEditDocumentDialogState();
}

class AddEditDocumentDialogState extends State<AddEditDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = _documentTypes.first;
  DateTime? _expiry;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _notesCtrl.text = existing.notes ?? '';
      _type =
          _documentTypes.contains(existing.type) ? existing.type : 'Other';
      _expiry = existing.expiry;
      _localPath = existing.localPath;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _attachPhoto() async {
    final picked = await pickPhotoFromCameraOrGallery(context);
    if (picked != null) setState(() => _localPath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Document' : 'Add Document'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _documentTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_expiry == null
                      ? 'No expiry date'
                      : 'Expires ${_formatDate(_expiry!)}'),
                  trailing: TextButton(
                      onPressed: _pickExpiry, child: const Text('Set')),
                ),
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
    final document = widget.existing ??
        (Document()
          ..supabaseId = 'doc_${DateTime.now().millisecondsSinceEpoch}'
          ..boatSupabaseId = '00000000-0000-0000-0000-000000000000');
    document
      ..title = _titleCtrl.text
      ..type = _type
      ..notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text
      ..expiry = _expiry
      ..localPath = _localPath;
    widget.onSave(document);
  }
}
