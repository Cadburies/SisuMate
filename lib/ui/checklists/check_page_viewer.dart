import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../services/free_edit_gate.dart';
import '../../services/revenuecat_service.dart';
import '../components/smart_image.dart';
import '../components/item_detail_shell.dart';
import '../components/common_drawer.dart';
import '../components/photo_source_picker.dart';

/// Swipeable checklist item detail (theme.md §7 / UX5).
/// Used by Checklists, Maintenance, and Safety via [showCheckPageViewer].
class CheckPageViewer extends ConsumerStatefulWidget {
  final List<ChecklistItem> items;
  final int initialIndex;
  final String groupName;

  const CheckPageViewer({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.groupName,
  });

  @override
  ConsumerState<CheckPageViewer> createState() => _CheckPageViewerState();
}

class _CheckPageViewerState extends ConsumerState<CheckPageViewer> {
  late List<ChecklistItem> _items;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<ChecklistItem>.from(widget.items);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  ChecklistItem _item(int i) => _items[i];

  void _loadEditors(int index) {
    final item = _item(index);
    _titleCtrl.text = item.title;
    _descCtrl.text = item.description ?? '';
    _notesCtrl.text = item.notes ?? '';
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  List<String> _history(ChecklistItem item) {
    final lines = <String>[];
    lines.add('Created ${_fmt(item.createdAt)}');
    // Newest first from completionHistory (ISO strings).
    final hist = List<String>.from(item.completionHistory.reversed);
    for (final iso in hist) {
      try {
        lines.add('Completed ${_fmt(DateTime.parse(iso))}');
      } catch (_) {
        lines.add('Completed $iso');
      }
    }
    if (item.isCompleted &&
        item.completedAt != null &&
        !item.completionHistory.contains(item.completedAt!.toIso8601String())) {
      lines.add('Completed ${_fmt(item.completedAt!)}');
    }
    if (item.isHidden) lines.add('Currently hidden');
    return lines;
  }

  Color _stateColor(ChecklistItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = item.isHidden
        ? ItemListState.hidden
        : item.isCompleted
            ? ItemListState.stocked
            : ItemListState.defaults;
    return SisuColors.itemStateColors(isDark, state).bg;
  }

  /// FREE-EDITS: completing/uncompleting and editing notes are Pro features
  /// (access_tiers.md), but Free gets [FreeEditGate.freeEditAllowance] tries
  /// as an upgrade teaser before hard-locking behind the paywall.
  Future<bool> _checkFreeEditGate() async {
    if (await FreeEditGate.tryConsume(ref)) {
      final remaining = await FreeEditGate.remaining(ref);
      if (remaining != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(remaining > 0
              ? 'Free preview: $remaining edit(s) left — upgrade for unlimited'
              : 'That was your last free edit — upgrade for unlimited'),
          duration: const Duration(seconds: 2),
        ));
      }
      return true;
    }
    if (!mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sisu Mate Pro Required'),
        content: const Text(
          'You\'ve used your free preview edits. Upgrade to Pro for '
          'unlimited completions, notes, and history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
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
    return false;
  }

  Future<void> _toggleCompletion(int index) async {
    if (!await _checkFreeEditGate()) return;
    final item = _item(index);
    await ref.read(checklistRepositoryProvider).toggleComplete(item);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.isCompleted
            ? '${item.title} completed'
            : '${item.title} marked as incomplete'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleHidden(int index) async {
    final item = _item(index);
    final repository = ref.read(checklistRepositoryProvider);
    if (item.isHidden) {
      await repository.unhideItem(item);
    } else {
      await repository.hideItem(item);
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            item.isHidden ? '${item.title} hidden' : '${item.title} unhidden'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteItem(int index) async {
    final item = _item(index);
    await ref.read(checklistRepositoryProvider).permanentlyDelete(item);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} deleted'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _changePhoto(int index) async {
    final item = _item(index);
    final picked = await pickPhotoFromCameraOrGallery(context);
    if (picked == null) return;
    item.userPhotoPath = picked.path;
    await ref.read(checklistRepositoryProvider).updateItem(item);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveEdit(int index) async {
    if (!await _checkFreeEditGate()) return;
    final item = _item(index);
    item.title = _titleCtrl.text.trim();
    item.description =
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    item.notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    await ref.read(checklistRepositoryProvider).updateItem(item);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ItemDetailShell(
      itemCount: _items.length,
      initialIndex: widget.initialIndex.clamp(0, _items.length - 1),
      titleForIndex: (i) => _item(i).title,
      subtitleForIndex: (i) =>
          '${widget.groupName} · ${i + 1} of ${_items.length}',
      stateColorForIndex: (i) => _stateColor(_item(i)),
      imageBuilder: (context, i) {
        final item = _item(i);
        return SmartImage(
          assetName: item.assetName,
          userPhotoUrl: item.userPhotoUrl,
          userPhotoPath: item.userPhotoPath,
          itemName: item.title,
          groupName: widget.groupName,
          fit: BoxFit.cover,
        );
      },
      onChangePhoto: (i) => () => _changePhoto(i),
      historyForIndex: (i) => _history(_item(i)),
      onSaveEdit: _saveEdit,
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeaderWidget(title: 'Item options'),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Refresh item'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
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
        final item = _item(index);
        final c = SisuColors.itemStateColors(
          isDark,
          item.isHidden
              ? ItemListState.hidden
              : item.isCompleted
                  ? ItemListState.stocked
                  : ItemListState.defaults,
        );
        if (isEditing) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleCtrl,
                  style: TextStyle(
                      color: c.title,
                      fontSize: 22,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: c.desc),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  maxLines: null,
                  minLines: 3,
                  style: TextStyle(color: c.desc, height: 1.4),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: c.desc),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: TextStyle(color: c.desc),
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: c.desc),
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.groupName,
                  style: TextStyle(color: c.desc, fontSize: 13)),
              const SizedBox(height: 6),
              Text(item.title,
                  style: TextStyle(
                      color: c.title,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              if (item.description != null) ...[
                const SizedBox(height: 10),
                Text(item.description!,
                    style: TextStyle(color: c.desc, fontSize: 15, height: 1.4)),
              ],
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Notes',
                    style: TextStyle(
                        color: c.title,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(item.notes!, style: TextStyle(color: c.desc)),
              ],
              const SizedBox(height: 12),
              Text(
                item.isCompleted
                    ? 'Status: completed'
                    : item.isHidden
                        ? 'Status: hidden'
                        : 'Status: open',
                style: TextStyle(color: c.desc, fontSize: 13),
              ),
            ],
          ),
        );
      },
      actionsForIndex:
          (context, index, isEditing, startEdit, cancelEdit, saveEdit) {
        final item = _item(index);
        if (isEditing) {
          return [
            DetailAction(
              icon: Icons.close,
              label: 'Cancel',
              onPressed: cancelEdit,
            ),
            DetailAction(
              icon: Icons.save,
              label: 'Save',
              onPressed: () => saveEdit(),
              color: SisuColors.completedBackground,
            ),
          ];
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // #185: background must hint the state this tap moves *into*, not
        // the current one — using the current state's color here is exactly
        // what made "Uncomplete" invisible against the completed (green)
        // sticky bar, since both were the same green.
        final destinationState = item.isCompleted
            ? SisuColors.itemStateColors(isDark, ItemListState.defaults)
            : SisuColors.itemStateColors(isDark, ItemListState.stocked);
        // #204: same rule as #185 above, applied to Hide/Unhide — the button
        // must preview the state the tap moves *into*. Both used to share
        // one static SisuColors.hideAction regardless of direction.
        final hideDestination =
            SisuColors.itemStateColors(isDark, ItemListState.hidden);
        final unhideDestination =
            SisuColors.itemStateColors(isDark, ItemListState.defaults);
        return [
          DetailAction(
            icon: item.isCompleted
                ? Icons.remove_done
                : Icons.check_circle_outline,
            label: item.isCompleted ? 'Uncomplete' : 'Complete',
            onPressed: () => _toggleCompletion(index),
            color: destinationState.bg,
            onColor: destinationState.title,
          ),
          if (!item.isHidden)
            DetailAction(
              icon: Icons.visibility_off,
              label: 'Hide',
              onPressed: () => _toggleHidden(index),
              color: hideDestination.bg,
              onColor: hideDestination.title,
            )
          else ...[
            DetailAction(
              icon: Icons.undo,
              label: 'Unhide',
              onPressed: () => _toggleHidden(index),
              color: unhideDestination.bg,
              onColor: unhideDestination.title,
            ),
            DetailAction(
              icon: Icons.delete_forever,
              label: 'Delete',
              onPressed: () => _deleteItem(index),
              color: Colors.red,
            ),
          ],
          DetailAction(
            icon: Icons.edit,
            label: 'Edit',
            onPressed: () {
              _loadEditors(index);
              startEdit();
            },
          ),
        ];
      },
    );
  }
}

/// Bundles [CheckPageViewer]'s constructor args for passing through
/// GoRouter's `extra` to whichever module's item-detail route pushed it.
class CheckPageViewerArgs {
  final List<ChecklistItem> items;
  final int initialIndex;
  final String groupName;

  const CheckPageViewerArgs({
    required this.items,
    required this.initialIndex,
    required this.groupName,
  });
}

extension CheckPageViewerExtension on BuildContext {
  /// [routePath] is the caller's module-specific named route (e.g.
  /// `AppRoutes.checklistItemDetail`, `.safetyItemDetail`, `.maintenanceItemDetail`)
  /// — all three render this same [CheckPageViewer] widget.
  void showCheckPageViewer({
    required List<ChecklistItem> items,
    required int initialIndex,
    required String groupName,
    required String routePath,
  }) {
    if (items.isEmpty) return;
    final idx = initialIndex < 0 ? 0 : initialIndex.clamp(0, items.length - 1);
    push(
      routePath,
      extra: CheckPageViewerArgs(
        items: items,
        initialIndex: idx,
        groupName: groupName,
      ),
    );
  }
}
