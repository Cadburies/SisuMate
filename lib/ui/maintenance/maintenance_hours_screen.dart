import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/title_tile.dart';
import '../components/main_list_tile.dart';
import '../components/common_drawer.dart';
import '../components/record_detail_screen.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/revenuecat_service.dart';
import '../../services/suggestion_engine.dart';
import 'maintenance_risk_triage_dialog.dart';

String _formatDate(DateTime d) => d.toString().split(' ')[0];

String _intervalTag(MaintenanceTask t) {
  final parts = <String>[];
  if (t.intervalHours != null) parts.add('${t.intervalHours}h');
  if (t.intervalMonths != null) parts.add('${t.intervalMonths}mo');
  return parts.isEmpty ? 'No interval set' : parts.join(' / ');
}

/// #216: the data-entry UI `MaintenanceTask` never had — logging engine
/// hours / a last-serviced date against a maintenance task, and (via the
/// distinct purple AI icon, #208) sending the whole backlog to an LLM for a
/// risk-ranked, failure-mode-focused triage instead of the plain due/overdue
/// flag the offline rules in `SuggestionEngine` already give for free.
class MaintenanceHoursScreen extends ConsumerWidget {
  const MaintenanceHoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(isProProvider);
    final isPro = isProAsync.value ?? false;
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final tasks = tasksAsync.value ?? const <MaintenanceTask>[];
    final now = DateTime.now();
    const engine = SuggestionEngine();

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Engine Hours & Service Log',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                // #208: AI risk triage gets its own distinct entry point,
                // never blended into the offline add/edit actions below.
                actionsBuilder: (color) => [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome,
                        color: Colors.deepPurple),
                    tooltip: 'AI: Risk-ranked maintenance triage',
                    onPressed: tasks.isEmpty
                        ? null
                        : () => showDialog<void>(
                              context: context,
                              builder: (_) =>
                                  MaintenanceRiskTriageDialog(tasks: tasks),
                            ),
                  ),
                ],
              ),
              Expanded(
                child: tasksAsync.when(
                  data: (_) {
                    if (tasks.isEmpty) {
                      return const Center(
                          child: Text(
                              'No maintenance tasks logged yet — add one '
                              'with engine hours or a service interval.'));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: tasks.length,
                      itemBuilder: (context, i) {
                        final task = tasks[i];
                        final due = engine.dueInfoFor(task, now);
                        return MainListTile(
                          onTap: () => _showDetail(context, ref, task, isPro),
                          header: MainListTile.iconHeader(
                            icon: Icons.build_circle_outlined,
                            iconColor: Colors.orange,
                          ),
                          title: task.description.isEmpty
                              ? 'Untitled task'
                              : task.description,
                          tags: [_intervalTag(task)],
                          tagColor: Colors.orange,
                          metaLine: task.lastDoneDate != null
                              ? 'Last done ${_formatDate(task.lastDoneDate!)}'
                              : (task.lastDoneHours != null
                                  ? 'Last done at ${task.lastDoneHours}h'
                                  : 'Never logged done'),
                          attentionLine: due?.overdue == true ? due!.detail : null,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error loading maintenance log: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => isPro
            ? _showAddEditDialog(context, ref)
            : _showProRequiredDialog(context),
        tooltip: isPro ? 'Add maintenance task' : 'Upgrade to Pro',
        child: Icon(isPro ? Icons.add : Icons.lock_outline),
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
        content: const Text('Logging engine hours and service history is a '
            'Pro feature. Upgrade to unlock the maintenance log.'),
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
      BuildContext context, WidgetRef ref, MaintenanceTask task, bool isPro) {
    final tasks =
        ref.read(maintenanceTasksProvider).asData?.value ?? [task];
    final index = tasks.indexWhere((t) => t.supabaseId == task.supabaseId);
    final list = index < 0 ? [task] : tasks;
    final start = index < 0 ? 0 : index;

    context.push(
      AppRoutes.maintenanceHoursDetail,
      extra: RecordDetailArgs(
        itemCount: list.length,
        initialIndex: start,
        canEdit: isPro,
        titleForIndex: (i) => list[i].description.isEmpty
            ? 'Untitled task'
            : list[i].description,
        historyForIndex: (i) => [
          'Last modified: ${list[i].lastModified.toLocal()}',
        ],
        fieldsForIndex: (i) {
          final t = list[i];
          return [
            RecordField(
                key: 'description', label: 'Description', value: t.description),
            RecordField(
                key: 'intervalHours',
                label: 'Interval (engine hours)',
                value: t.intervalHours?.toString() ?? '',
                isNumber: true),
            RecordField(
                key: 'intervalMonths',
                label: 'Interval (months)',
                value: t.intervalMonths?.toString() ?? '',
                isNumber: true),
            RecordField(
                key: 'lastDoneHours',
                label: 'Done at engine hours',
                value: t.lastDoneHours?.toString() ?? '',
                isNumber: true),
            RecordField(
                key: 'lastDoneDate',
                label: 'Last done date',
                value: t.lastDoneDate?.toIso8601String() ?? '',
                isDate: true),
            RecordField(
                key: 'doneBy', label: 'Done by', value: t.doneBy ?? ''),
            RecordField(
                key: 'notes',
                label: 'Notes',
                value: t.notes ?? '',
                multiline: true),
          ];
        },
        onSave: (i, values) async {
          final t = list[i];
          t
            ..description = values['description'] ?? t.description
            ..intervalHours = int.tryParse(values['intervalHours'] ?? '')
            ..intervalMonths = int.tryParse(values['intervalMonths'] ?? '')
            ..lastDoneHours = int.tryParse(values['lastDoneHours'] ?? '')
            ..lastDoneDate = DateTime.tryParse(values['lastDoneDate'] ?? '')
            ..doneBy =
                (values['doneBy'] ?? '').isEmpty ? null : values['doneBy']
            ..notes = (values['notes'] ?? '').isEmpty ? null : values['notes'];
          await ref.read(maintenanceRepositoryProvider).updateTask(t);
        },
        onDelete: isPro
            ? (i) =>
                ref.read(maintenanceRepositoryProvider).deleteTask(list[i])
            : null,
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AddEditMaintenanceTaskDialog(
        onSave: (task) async {
          final boat = await ref.read(activeBoatProvider.future);
          task
            ..supabaseId = 'maint_${DateTime.now().millisecondsSinceEpoch}'
            ..boatSupabaseId = boat?.supabaseId ?? '';
          await ref.read(maintenanceRepositoryProvider).addTask(task);
          navigator.pop();
          messenger.showSnackBar(
              const SnackBar(content: Text('Maintenance task saved')));
        },
      ),
    );
  }
}

class AddEditMaintenanceTaskDialog extends StatefulWidget {
  final void Function(MaintenanceTask) onSave;
  const AddEditMaintenanceTaskDialog({super.key, required this.onSave});

  @override
  State<AddEditMaintenanceTaskDialog> createState() =>
      AddEditMaintenanceTaskDialogState();
}

class AddEditMaintenanceTaskDialogState
    extends State<AddEditMaintenanceTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _intervalHoursCtrl = TextEditingController();
  final _intervalMonthsCtrl = TextEditingController();
  final _lastDoneHoursCtrl = TextEditingController();
  DateTime? _lastDoneDate;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _intervalHoursCtrl.dispose();
    _intervalMonthsCtrl.dispose();
    _lastDoneHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDoneDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _lastDoneDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Maintenance Task'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _intervalHoursCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Interval (engine hours)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty)
                      ? null
                      : (int.tryParse(v) == null ? 'Invalid number' : null),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _intervalMonthsCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Interval (months)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty)
                      ? null
                      : (int.tryParse(v) == null ? 'Invalid number' : null),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastDoneHoursCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Done at engine hours'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty)
                      ? null
                      : (int.tryParse(v) == null ? 'Invalid number' : null),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_lastDoneDate == null
                      ? 'Last done date: not set'
                      : 'Last done date: ${_formatDate(_lastDoneDate!)}'),
                  trailing:
                      TextButton(onPressed: _pickDate, child: const Text('Set')),
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
    final task = MaintenanceTask()
      ..description = _descriptionCtrl.text.trim()
      ..intervalHours = int.tryParse(_intervalHoursCtrl.text)
      ..intervalMonths = int.tryParse(_intervalMonthsCtrl.text)
      ..lastDoneHours = int.tryParse(_lastDoneHoursCtrl.text)
      ..lastDoneDate = _lastDoneDate;
    widget.onSave(task);
  }
}
