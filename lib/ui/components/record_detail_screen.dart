import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/colors.dart';
import 'item_detail_shell.dart';
import 'common_drawer.dart';
import 'photo_source_picker.dart';

/// Field descriptor for [RecordDetailScreen] edit/display (UX5).
class RecordField {
  final String key;
  final String label;
  final String value;
  final bool multiline;
  final bool isDate;
  final bool isNumber;
  final List<String>? options;

  const RecordField({
    required this.key,
    required this.label,
    required this.value,
    this.multiline = false,
    this.isDate = false,
    this.isNumber = false,
    this.options,
  });
}

/// Bundles [RecordDetailScreen]'s constructor args for passing through
/// GoRouter's `extra` to the shared detail named routes (fuel/crew/inventory/
/// documents each have their own route, all built from this one args class).
class RecordDetailArgs {
  final int itemCount;
  final int initialIndex;
  final String Function(int index) titleForIndex;
  final String? Function(int index)? photoPathForIndex;
  final List<RecordField> Function(int index) fieldsForIndex;
  final List<String> Function(int index)? historyForIndex;
  final Future<void> Function(int index, Map<String, String> values) onSave;
  final Future<void> Function(int index)? onDelete;
  final Future<void> Function(int index, String? path)? onPhotoChanged;
  final bool canEdit;

  const RecordDetailArgs({
    required this.itemCount,
    required this.initialIndex,
    required this.titleForIndex,
    this.photoPathForIndex,
    required this.fieldsForIndex,
    this.historyForIndex,
    required this.onSave,
    this.onDelete,
    this.onPhotoChanged,
    this.canEdit = true,
  });
}

/// Generic swipeable detail for record modules (Crew, Inventory, Documents, Fuel).
///
/// Modules pass the visible list, field extractors, and save/delete hooks.
class RecordDetailScreen extends ConsumerStatefulWidget {
  final int itemCount;
  final int initialIndex;
  final String Function(int index) titleForIndex;
  final String? Function(int index)? photoPathForIndex;
  final List<RecordField> Function(int index) fieldsForIndex;
  final List<String> Function(int index)? historyForIndex;
  final Future<void> Function(int index, Map<String, String> values) onSave;
  final Future<void> Function(int index)? onDelete;
  final Future<void> Function(int index, String? path)? onPhotoChanged;
  final bool canEdit;

  const RecordDetailScreen({
    super.key,
    required this.itemCount,
    required this.initialIndex,
    required this.titleForIndex,
    this.photoPathForIndex,
    required this.fieldsForIndex,
    this.historyForIndex,
    required this.onSave,
    this.onDelete,
    this.onPhotoChanged,
    this.canEdit = true,
  });

  @override
  ConsumerState<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends ConsumerState<RecordDetailScreen> {
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, String> _dropdowns = {};
  final Map<String, DateTime?> _dates = {};

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _prepareEditors(int index) {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _ctrls.clear();
    _dropdowns.clear();
    _dates.clear();
    for (final f in widget.fieldsForIndex(index)) {
      if (f.options != null) {
        _dropdowns[f.key] =
            f.options!.contains(f.value) ? f.value : f.options!.first;
      } else if (f.isDate) {
        _dates[f.key] = f.value.isEmpty ? null : DateTime.tryParse(f.value);
      } else {
        _ctrls[f.key] = TextEditingController(text: f.value);
      }
    }
  }

  Map<String, String> _collectValues() {
    final map = <String, String>{};
    for (final e in _ctrls.entries) {
      map[e.key] = e.value.text.trim();
    }
    for (final e in _dropdowns.entries) {
      map[e.key] = e.value;
    }
    for (final e in _dates.entries) {
      map[e.key] = e.value?.toIso8601String() ?? '';
    }
    return map;
  }

  Future<void> _pickPhoto(int index) async {
    if (widget.onPhotoChanged == null) return;
    final picked = await pickPhotoFromCameraOrGallery(context);
    if (picked == null) return;
    await widget.onPhotoChanged!(index, picked.path);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ItemDetailShell(
      itemCount: widget.itemCount,
      initialIndex: widget.initialIndex,
      titleForIndex: widget.titleForIndex,
      subtitleForIndex: (i) => '${i + 1} of ${widget.itemCount}',
      historyForIndex: widget.historyForIndex ??
          (i) {
            final mods = widget
                .fieldsForIndex(i)
                .where((f) => f.key == 'lastModified')
                .map((f) => f.value);
            final mod = mods.isEmpty ? '—' : mods.first;
            return ['Last modified: $mod'];
          },
      imageBuilder: widget.photoPathForIndex == null
          ? null
          : (context, i) {
              final path = widget.photoPathForIndex!(i);
              if (path != null && path.isNotEmpty && File(path).existsSync()) {
                return Image.file(File(path), fit: BoxFit.cover);
              }
              return Container(
                color: SisuColors.getListSurface(isDark),
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_outlined,
                  size: 56,
                  color: SisuColors.getTextSecondaryColor(isDark),
                ),
              );
            },
      onChangePhoto: widget.onPhotoChanged == null || !widget.canEdit
          ? null
          : (i) => () => _pickPhoto(i),
      onSaveEdit: (i) async {
        final messenger = ScaffoldMessenger.of(context);
        await widget.onSave(i, _collectValues());
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Saved'), duration: Duration(seconds: 1)),
        );
      },
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeaderWidget(title: 'Item options'),
              const Divider(),
              SectionHeader(title: 'Account'),
              AccountSection(),
              ProUpgradeSection(),
              AboutSection(),
              const Spacer(),
              DrawerFooter(),
            ],
          ),
        ),
      ),
      contentBuilder: (context, index, isEditing) {
        final fields = widget.fieldsForIndex(index);
        final titleColor = SisuColors.getTextPrimaryColor(isDark);
        final descColor = SisuColors.getTextSecondaryColor(isDark);

        if (isEditing) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in fields) ...[
                  if (f.key == 'lastModified')
                    const SizedBox.shrink()
                  else if (f.options != null)
                    DropdownButtonFormField<String>(
                      initialValue: _dropdowns[f.key],
                      decoration: InputDecoration(labelText: f.label),
                      items: f.options!
                          .map((o) =>
                              DropdownMenuItem(value: o, child: Text(o)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _dropdowns[f.key] = v);
                      },
                    )
                  else if (f.isDate)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.label),
                      subtitle: Text(_dates[f.key] == null
                          ? 'Not set'
                          : _dates[f.key]!.toLocal().toString().split(' ').first),
                      trailing: TextButton(
                        child: const Text('Set'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dates[f.key] ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _dates[f.key] = picked);
                          }
                        },
                      ),
                    )
                  else
                    TextField(
                      controller: _ctrls[f.key],
                      keyboardType: f.isNumber
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      maxLines: f.multiline ? 3 : 1,
                      decoration: InputDecoration(labelText: f.label),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.titleForIndex(index),
                style: TextStyle(
                  color: titleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              for (final f in fields)
                if (f.key != 'lastModified' && f.value.isNotEmpty) ...[
                  Text(f.label,
                      style: TextStyle(
                          color: descColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    f.isDate && f.value.isNotEmpty
                        ? (DateTime.tryParse(f.value)
                                ?.toLocal()
                                .toString()
                                .split(' ')
                                .first ??
                            f.value)
                        : f.value,
                    style: TextStyle(color: titleColor, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
      actionsForIndex:
          (context, index, isEditing, startEdit, cancelEdit, saveEdit) {
        if (!widget.canEdit) {
          return [
            DetailAction(
              icon: Icons.lock,
              label: 'Pro',
              onPressed: () {},
            ),
          ];
        }
        if (isEditing) {
          return [
            DetailAction(
                icon: Icons.close, label: 'Cancel', onPressed: cancelEdit),
            DetailAction(
              icon: Icons.save,
              label: 'Save',
              onPressed: () => saveEdit(),
              color: SisuColors.completedBackground,
            ),
          ];
        }
        return [
          if (widget.onDelete != null)
            DetailAction(
              icon: Icons.delete_forever,
              label: 'Delete',
              color: Colors.red,
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete?'),
                    content: Text('Delete "${widget.titleForIndex(index)}"?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await widget.onDelete!(index);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
          DetailAction(
            icon: Icons.edit,
            label: 'Edit',
            onPressed: () {
              _prepareEditors(index);
              startEdit();
            },
          ),
        ];
      },
    );
  }
}
