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
import 'travel_safety_dialog.dart';

final crewMembersProvider = StreamProvider<List<CrewMember>>((ref) {
  return ref.watch(crewMemberRepositoryProvider).watchCrewMembers();
});

const _crewRoles = [
  'Captain',
  'First Mate',
  'Engineer',
  'Cook',
  'Crew',
  'Guest',
];

// #324 — must match guest_profiles_screen.dart's `_allergens`/`_dietaryTags`
// vocabulary exactly, since "Copy to Guest Profile" carries these tags
// straight across.
const _crewAllergens = [
  'gluten', 'dairy', 'eggs', 'nuts', 'peanuts', 'shellfish',
  'fish', 'soy', 'sesame', 'sulphites', 'mustard', 'celery',
  'lupin', 'molluscs',
];

const _crewDietaryTags = [
  'vegan', 'vegetarian', 'gluten-free', 'dairy-free', 'egg-free',
  'nut-free', 'keto', 'paleo', 'halal', 'kosher', 'low-carb', 'low-sodium',
];

class CrewScreen extends ConsumerStatefulWidget {
  const CrewScreen({super.key});

  @override
  ConsumerState<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends ConsumerState<CrewScreen> {
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

  Future<void> _shareSelected(List<CrewMember> all) async {
    final selected =
        all.where((m) => _selectedIds.contains(m.id)).toList();
    final messenger = ScaffoldMessenger.of(context);
    if (selected.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Select at least one crew member')));
      return;
    }
    await RecordShareService.shareCrew(selected);
    if (mounted) _exitSelection();
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final crewAsync = ref.watch(crewMembersProvider);
    final isPro = isProAsync.value ?? false;
    final allMembers = crewAsync.value ?? const <CrewMember>[];

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: _selecting
                    ? '${_selectedIds.length} selected'
                    : 'Crew & Contacts',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                actionsBuilder: (color) => _selecting
                    ? [
                        IconButton(
                          icon: Icon(Icons.share, color: color),
                          tooltip: 'Share selected',
                          onPressed: () => _shareSelected(allMembers),
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
                        // #208: AI actions get their own distinct entry
                        // point, never blended into the offline actions.
                        IconButton(
                          icon: const Icon(Icons.auto_awesome,
                              color: Colors.deepPurple),
                          tooltip: 'AI: Travel & entry safety',
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => const TravelSafetyDialog(),
                          ),
                        ),
                        if (isPro && allMembers.isNotEmpty)
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
                              kind: ImportService.kindCrew,
                              label: 'Crew',
                              fileBaseName: 'sisu_crew',
                              exportCurrent: () async =>
                                  ImportService.exportCrew(allMembers),
                              existingNames: () async =>
                                  allMembers.map((e) => e.name).toList(),
                              persist: (batch) async {
                                final repo =
                                    ref.read(crewMemberRepositoryProvider);
                                final existing =
                                    await repo.watchCrewMembers().first;
                                var inserted = 0;
                                var updated = 0;
                                for (final m in batch.crewMembers) {
                                  final match = ImportService.matchExisting(
                                    existing: existing,
                                    incomingId: m.supabaseId,
                                    idOf: (e) => e.supabaseId,
                                    contentKeyOf: ImportService.contentKeyCrew,
                                    incomingContentKey:
                                        ImportService.contentKeyCrew(m),
                                  );
                                  if (match != null) {
                                    m.supabaseId = match.supabaseId;
                                    m.id = match.id;
                                    await repo.updateCrewMember(m);
                                    updated++;
                                  } else {
                                    await repo.addCrewMember(m);
                                    existing.add(m);
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
                  hintText: 'Search crew...',
                  onChanged: (v) => setState(() => _search = v),
                ),
              Expanded(
                child: crewAsync.when(
                  data: (members) {
                    final filtered = members.where((m) {
                      if (_search.isEmpty) return true;
                      final q = _search.toLowerCase();
                      return m.name.toLowerCase().contains(q) ||
                          m.role.toLowerCase().contains(q) ||
                          (m.phone?.toLowerCase().contains(q) ?? false);
                    }).toList();
                    if (filtered.isEmpty) {
                      return Center(
                          child: Text(members.isEmpty
                              ? 'No crew members yet'
                              : 'No matches'));
                    }
                    if (_selecting) {
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final member = filtered[i];
                          return ThemedStateTile(
                            state: ItemListState.defaults,
                            leading: Checkbox(
                              value: _selectedIds.contains(member.id),
                              onChanged: (_) => _toggle(member.id),
                            ),
                            title: member.name,
                            subtitle: member.role,
                            onTap: () => _toggle(member.id),
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
                        final member = filtered[i];
                        Widget header;
                        if (member.localPath != null &&
                            File(member.localPath!).existsSync()) {
                          header = ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.file(
                              File(member.localPath!),
                              height: 80,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          header = MainListTile.iconHeader(
                            icon: Icons.person,
                            iconColor: Colors.teal,
                          );
                        }
                        return MainListTile(
                          onTap: () =>
                              _showDetail(context, ref, member, isPro),
                          header: header,
                          title: member.name,
                          tags: [member.role],
                          tagColor: Colors.teal,
                          countLine: (member.phone != null &&
                                  member.phone!.isNotEmpty)
                              ? member.phone
                              : null,
                          metaLine: (member.email != null &&
                                  member.email!.isNotEmpty)
                              ? member.email
                              : null,
                          attentionLine: (member.iceContact != null &&
                                  member.iceContact!.isNotEmpty)
                              ? 'ICE: ${member.iceContact}'
                              : null,
                          badges: [
                            if (member.certifications != null &&
                                member.certifications!.isNotEmpty)
                              member.certifications!,
                          ],
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
              tooltip: 'Add crew member',
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
            'Adding and editing crew members is a Pro feature. Upgrade to unlock crew management.'),
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
      BuildContext context, WidgetRef ref, CrewMember member, bool isPro) {
    final members = ref.read(crewMembersProvider).asData?.value ?? [member];
    final index = members.indexWhere((m) => m.supabaseId == member.supabaseId);
    final list = index < 0 ? [member] : members;
    final start = index < 0 ? 0 : index;

    context.push(
      AppRoutes.crewDetail,
      extra: RecordDetailArgs(
          itemCount: list.length,
          initialIndex: start,
          canEdit: isPro,
          titleForIndex: (i) => list[i].name,
          photoPathForIndex: (i) => list[i].localPath,
          historyForIndex: (i) => [
            'Last modified: ${list[i].lastModified.toLocal()}',
          ],
          fieldsForIndex: (i) {
            final m = list[i];
            return [
              RecordField(key: 'name', label: 'Name', value: m.name),
              RecordField(
                  key: 'role',
                  label: 'Role',
                  value: m.role,
                  options: _crewRoles),
              RecordField(key: 'phone', label: 'Phone', value: m.phone ?? ''),
              RecordField(key: 'email', label: 'Email', value: m.email ?? ''),
              RecordField(
                  key: 'iceContact',
                  label: 'ICE contact',
                  value: m.iceContact ?? ''),
              RecordField(
                  key: 'certifications',
                  label: 'Certifications',
                  value: m.certifications ?? '',
                  multiline: true),
              // #326 — port-entry/customs fields, all optional.
              RecordField(
                  key: 'dateOfBirth',
                  label: 'Date of birth',
                  value: m.dateOfBirth?.toIso8601String() ?? '',
                  isDate: true),
              RecordField(
                  key: 'nationality',
                  label: 'Nationality',
                  value: m.nationality ?? ''),
              RecordField(
                  key: 'passportNumber',
                  label: 'Passport number',
                  value: m.passportNumber ?? ''),
              RecordField(
                  key: 'lastModified',
                  label: 'Last modified',
                  value: m.lastModified.toIso8601String()),
            ];
          },
          onSave: (i, values) async {
            final m = list[i];
            m
              ..name = values['name'] ?? m.name
              ..role = values['role'] ?? m.role
              ..phone = (values['phone'] ?? '').isEmpty ? null : values['phone']
              ..email = (values['email'] ?? '').isEmpty ? null : values['email']
              ..iceContact = (values['iceContact'] ?? '').isEmpty
                  ? null
                  : values['iceContact']
              ..certifications = (values['certifications'] ?? '').isEmpty
                  ? null
                  : values['certifications']
              ..dateOfBirth = (values['dateOfBirth'] ?? '').isEmpty
                  ? null
                  : DateTime.tryParse(values['dateOfBirth']!)
              ..nationality = (values['nationality'] ?? '').isEmpty
                  ? null
                  : values['nationality']
              ..passportNumber = (values['passportNumber'] ?? '').isEmpty
                  ? null
                  : values['passportNumber'];
            await ref.read(crewMemberRepositoryProvider).updateCrewMember(m);
          },
          onDelete: isPro
              ? (i) => ref
                  .read(crewMemberRepositoryProvider)
                  .deleteCrewMember(list[i])
              : null,
          onPhotoChanged: isPro
              ? (i, path) async {
                  list[i].localPath = path;
                  await ref
                      .read(crewMemberRepositoryProvider)
                      .updateCrewMember(list[i]);
                }
              : null,
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {CrewMember? existing}) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AddEditCrewMemberDialog(
        existing: existing,
        onSave: (member) async {
          final repo = ref.read(crewMemberRepositoryProvider);
          if (existing == null) {
            await repo.addCrewMember(member);
          } else {
            await repo.updateCrewMember(member);
          }
          navigator.pop();
          messenger.showSnackBar(
              SnackBar(content: Text('${member.name} saved')));
        },
        // #324 — one-time copy, not a live link (GuestProfile is
        // local-only, no supabaseId, so a stored link would break on
        // any other device sharing this boat — see the model's doc).
        onCopyToGuestProfile: (member) async {
          final profile = GuestProfile()
            ..name = member.name
            ..allergenRestrictions = List.of(member.allergenRestrictions)
            ..dietaryRequirements = List.of(member.dietaryRequirements);
          await ref.read(guestProfileRepositoryProvider).addProfile(profile);
          messenger.showSnackBar(SnackBar(
              content:
                  Text('Guest profile created for ${member.name}')));
        },
      ),
    );
  }
}

class AddEditCrewMemberDialog extends StatefulWidget {
  final CrewMember? existing;
  final void Function(CrewMember) onSave;
  /// #324 — only offered when editing (an existing member with tags set is
  /// worth copying); null hides the action entirely.
  final void Function(CrewMember)? onCopyToGuestProfile;
  const AddEditCrewMemberDialog({
    super.key,
    this.existing,
    required this.onSave,
    this.onCopyToGuestProfile,
  });

  @override
  State<AddEditCrewMemberDialog> createState() =>
      AddEditCrewMemberDialogState();
}

class AddEditCrewMemberDialogState extends State<AddEditCrewMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _iceCtrl = TextEditingController();
  final _certsCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();
  String _role = 'Crew';
  String? _localPath;
  DateTime? _dateOfBirth;
  final Set<String> _allergens = {};
  final Set<String> _dietaryTags = {};

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _phoneCtrl.text = existing.phone ?? '';
      _emailCtrl.text = existing.email ?? '';
      _iceCtrl.text = existing.iceContact ?? '';
      _certsCtrl.text = existing.certifications ?? '';
      _nationalityCtrl.text = existing.nationality ?? '';
      _passportCtrl.text = existing.passportNumber ?? '';
      _role = _crewRoles.contains(existing.role) ? existing.role : 'Crew';
      _localPath = existing.localPath;
      _dateOfBirth = existing.dateOfBirth;
      _allergens.addAll(existing.allergenRestrictions);
      _dietaryTags.addAll(existing.dietaryRequirements);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _iceCtrl.dispose();
    _certsCtrl.dispose();
    _nationalityCtrl.dispose();
    _passportCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _attachPhoto() async {
    final picked = await pickPhotoFromCameraOrGallery(context);
    if (picked != null) setState(() => _localPath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Crew Member' : 'Add Crew Member'),
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
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _crewRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _iceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'In Case of Emergency contact'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _certsCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Certifications'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                // #326 — optional; only needed for an international
                // passage, but this is what a real port-entry crew list
                // needs (name, DOB, nationality, passport #, role).
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateOfBirth,
                        icon: const Icon(Icons.cake_outlined),
                        label: Text(_dateOfBirth == null
                            ? 'Date of birth'
                            : '${_dateOfBirth!.toLocal()}'.split(' ').first),
                      ),
                    ),
                    if (_dateOfBirth != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _dateOfBirth = null),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nationalityCtrl,
                  decoration: const InputDecoration(labelText: 'Nationality'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passportCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Passport number'),
                ),
                const SizedBox(height: 12),
                // #324 — same tag vocabulary as Chef's Guest Profiles.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Allergens', style: Theme.of(context).textTheme.labelLarge),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final a in _crewAllergens)
                      FilterChip(
                        label: Text(a),
                        selected: _allergens.contains(a),
                        onSelected: (v) => setState(
                            () => v ? _allergens.add(a) : _allergens.remove(a)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Dietary', style: Theme.of(context).textTheme.labelLarge),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final d in _crewDietaryTags)
                      FilterChip(
                        label: Text(d),
                        selected: _dietaryTags.contains(d),
                        onSelected: (v) => setState(
                            () => v ? _dietaryTags.add(d) : _dietaryTags.remove(d)),
                      ),
                  ],
                ),
                if (widget.existing != null &&
                    widget.onCopyToGuestProfile != null &&
                    (_allergens.isNotEmpty || _dietaryTags.isNotEmpty))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => widget.onCopyToGuestProfile!(
                        // Current on-screen state (name/tags the user may
                        // have just checked), not the last-saved record.
                        CrewMember()
                          ..name = _nameCtrl.text
                          ..allergenRestrictions = _allergens.toList()
                          ..dietaryRequirements = _dietaryTags.toList(),
                      ),
                      icon: const Icon(Icons.content_copy),
                      label: const Text('Copy to Guest Profile'),
                    ),
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
    final member = widget.existing ??
        (CrewMember()
          ..supabaseId = 'crew_${DateTime.now().millisecondsSinceEpoch}'
          ..boatSupabaseId = '00000000-0000-0000-0000-000000000000');
    member
      ..name = _nameCtrl.text
      ..role = _role
      ..phone = _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text
      ..email = _emailCtrl.text.isEmpty ? null : _emailCtrl.text
      ..iceContact = _iceCtrl.text.isEmpty ? null : _iceCtrl.text
      ..certifications = _certsCtrl.text.isEmpty ? null : _certsCtrl.text
      ..localPath = _localPath
      ..dateOfBirth = _dateOfBirth
      ..nationality =
          _nationalityCtrl.text.isEmpty ? null : _nationalityCtrl.text
      ..passportNumber =
          _passportCtrl.text.isEmpty ? null : _passportCtrl.text
      ..allergenRestrictions = _allergens.toList()
      ..dietaryRequirements = _dietaryTags.toList();
    widget.onSave(member);
  }
}
