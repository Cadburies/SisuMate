import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../models/models.dart';

const _allergens = [
  'gluten', 'dairy', 'eggs', 'nuts', 'peanuts', 'shellfish',
  'fish', 'soy', 'sesame', 'sulphites', 'mustard', 'celery',
  'lupin', 'molluscs',
];

const _dietaryTags = [
  'vegan', 'vegetarian', 'gluten-free', 'dairy-free', 'egg-free',
  'nut-free', 'keto', 'paleo', 'halal', 'kosher', 'low-carb', 'low-sodium',
];

class GuestProfilesScreen extends ConsumerWidget {
  const GuestProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(guestProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guest Profiles')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No guest profiles yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Tap + to add a profile for a guest\'s dietary needs.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: SisuColors.incompleteBackground,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(profile.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      )),
                  subtitle: _ProfileSummary(profile: profile),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: SisuColors.incompleteBackground,
                        onPressed: () => _showEditDialog(context, ref, profile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => _confirmDelete(context, ref, profile),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        backgroundColor: SisuColors.completedBackground,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, GuestProfile? existing) {
    showDialog<void>(
      context: context,
      builder: (_) => AddEditGuestProfileDialog(
        existing: existing,
        onSave: (profile) async {
          final repo = ref.read(guestProfileRepositoryProvider);
          if (existing == null) {
            await repo.addProfile(profile);
          } else {
            await repo.updateProfile(profile);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, GuestProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text('Remove "${profile.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(guestProfileRepositoryProvider).deleteProfile(profile);
    }
  }
}

class _ProfileSummary extends StatelessWidget {
  final GuestProfile profile;
  const _ProfileSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (profile.allergenRestrictions.isNotEmpty) {
      parts.add('Avoids: ${profile.allergenRestrictions.take(3).join(", ")}');
    }
    if (profile.dietaryRequirements.isNotEmpty) {
      parts.add(profile.dietaryRequirements.take(3).join(', '));
    }
    if (parts.isEmpty) {
      return Text('No restrictions set',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts
          .map((p) => Text(p,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis))
          .toList(),
    );
  }
}

/// Create / edit a guest dietary profile (TEST5 — public for widget tests).
class AddEditGuestProfileDialog extends StatefulWidget {
  final GuestProfile? existing;
  final Future<void> Function(GuestProfile) onSave;
  const AddEditGuestProfileDialog({
    super.key,
    required this.existing,
    required this.onSave,
  });

  @override
  State<AddEditGuestProfileDialog> createState() =>
      AddEditGuestProfileDialogState();
}

class AddEditGuestProfileDialogState extends State<AddEditGuestProfileDialog> {
  late final TextEditingController _nameCtrl;
  late Set<String> _selectedAllergens;
  late Set<String> _selectedDietary;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _selectedAllergens = Set.from(e?.allergenRestrictions ?? []);
    _selectedDietary = Set.from(e?.dietaryRequirements ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Profile' : 'New Guest Profile'),
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Alice',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Cannot eat (allergens):',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _allergens
                  .map((a) => FilterChip(
                        label: Text(a, style: const TextStyle(fontSize: 12)),
                        selected: _selectedAllergens.contains(a),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.2),
                        checkmarkColor: Theme.of(context).colorScheme.error,
                        onSelected: (sel) => setState(() =>
                            sel
                                ? _selectedAllergens.add(a)
                                : _selectedAllergens.remove(a)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Dietary requirements:',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _dietaryTags
                  .map((d) => FilterChip(
                        label: Text(d, style: const TextStyle(fontSize: 12)),
                        selected: _selectedDietary.contains(d),
                        selectedColor: SisuColors.completedBackground
                            .withValues(alpha: 0.2),
                        checkmarkColor: SisuColors.completedBackground,
                        onSelected: (sel) => setState(() =>
                            sel
                                ? _selectedDietary.add(d)
                                : _selectedDietary.remove(d)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _nameCtrl.text.trim().isEmpty
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  final profile = widget.existing ?? GuestProfile();
                  profile
                    ..name = _nameCtrl.text.trim()
                    ..allergenRestrictions = _selectedAllergens.toList()
                    ..dietaryRequirements = _selectedDietary.toList();
                  await widget.onSave(profile);
                  if (mounted) navigator.pop();
                },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
