import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/title_tile.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart';
import '../../services/error_log_service.dart';

class BoatsScreen extends ConsumerStatefulWidget {
  const BoatsScreen({super.key});

  @override
  ConsumerState<BoatsScreen> createState() => _BoatsScreenState();
}

class _BoatsScreenState extends ConsumerState<BoatsScreen> {
  @override
  Widget build(BuildContext context) {
    final boatsAsync = ref.watch(boatsProvider);
    final isProAsync = ref.watch(isProProvider);
    final activeBoatAsync = ref.watch(activeBoatProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TitleTile(title: 'My Boats'),
            Expanded(
              child: isProAsync.when(
                data: (isPro) => boatsAsync.when(
                  data: (boats) {
                    if (boats.isEmpty) {
                      return const Center(
                        child: Text('No boats found'),
                      );
                    }

                    return activeBoatAsync.when(
                      data: (activeBoat) => ListView.builder(
                        itemCount: boats.length,
                        itemBuilder: (context, index) {
                          final boat = boats[index];
                          final isActive = activeBoat?.supabaseId == boat.supabaseId;

                          return BoatListTile(
                            boat: boat,
                            isActive: isActive,
                            isPro: isPro,
                            onTap: () => _selectBoat(context, ref, boat),
                            onEdit: isPro ? () => _showEditBoatDialog(context, ref, boat) : null,
                            onDelete: isPro && boats.length > 1 ? () => _showDeleteBoatDialog(context, ref, boat) : null,
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error loading active boat: $e')),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading boats: $e')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('Error loading subscription status')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isProAsync.when(
        data: (isPro) => isPro
            ? FloatingActionButton(
                onPressed: () => _showAddBoatDialog(context, ref),
                child: const Icon(Icons.add),
              )
            : null,
        loading: () => null,
        error: (_, _) => null,
      ),
    );
  }

  void _selectBoat(BuildContext context, WidgetRef ref, Boat boat) async {
    final userSettings = await ref.read(userSettingsProvider.future);
    if (userSettings != null) {
      userSettings.activeBoatSupabaseId = boat.supabaseId;
      await ref.read(userSettingsRepositoryProvider).updateSettings(userSettings);
      ref.invalidate(userSettingsProvider);
      ref.invalidate(activeBoatProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to ${boat.name}')),
        );
      }
    }
  }

  void _showAddBoatDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Boat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Boat Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final boat = Boat()
                  ..supabaseId = 'user_boat_${DateTime.now().millisecondsSinceEpoch}'
                  ..name = name
                  // Without this, boats_insert's `ownerId = auth.uid()` RLS
                  // check always rejects the push (#200/#201) — the row can
                  // never sync, silently staying local-only forever.
                  ..ownerId = ref.read(authServiceProvider).currentUser?.id;

                try {
                  final repository = ref.read(boatRepositoryProvider);
                  await repository.addBoat(boat);

                  navigator.pop();

                  // Refresh boats list
                  ref.invalidate(boatsProvider);

                  messenger.showSnackBar(
                    SnackBar(content: Text('${boat.name} added successfully')),
                  );
                } catch (e, st) {
                  unawaited(ErrorLogService()
                      .logException(e, st, context: 'boats_screen: add boat'));
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error adding boat: $e')),
                  );
                }
              }
            },
            child: const Text('Add Boat'),
          ),
        ],
      ),
    );
  }

  void _showEditBoatDialog(BuildContext context, WidgetRef ref, Boat boat) {
    final nameController = TextEditingController(text: boat.name);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Boat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Boat Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty && name != boat.name) {
                final updatedBoat = boat..name = name;

                try {
                  final repository = ref.read(boatRepositoryProvider);
                  await repository.updateBoat(updatedBoat);

                  navigator.pop();

                  // Refresh boats list and active boat
                  ref.invalidate(boatsProvider);
                  ref.invalidate(activeBoatProvider);

                  messenger.showSnackBar(
                    SnackBar(content: Text('${updatedBoat.name} updated successfully')),
                  );
                } catch (e, st) {
                  unawaited(ErrorLogService()
                      .logException(e, st, context: 'boats_screen: update boat'));
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error updating boat: $e')),
                  );
                }
              } else {
                navigator.pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBoatDialog(BuildContext context, WidgetRef ref, Boat boat) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Boat'),
        content: Text(
          'Are you sure you want to delete "${boat.name}"? This will permanently delete all associated data including checklists, shopping lists, logs, and maintenance records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repository = ref.read(boatRepositoryProvider);
                await repository.deleteBoat(boat);

                navigator.pop();

                // If this was the active boat, switch to the first remaining boat or clear
                final userSettings = await ref.read(userSettingsProvider.future);
                if (userSettings != null && userSettings.activeBoatSupabaseId == boat.supabaseId) {
                  final remaining = await ref.read(boatsProvider.future);
                  userSettings.activeBoatSupabaseId = remaining.isNotEmpty ? remaining.first.supabaseId : null;
                  await ref.read(userSettingsRepositoryProvider).updateSettings(userSettings);
                }

                // Refresh all providers
                ref.invalidate(boatsProvider);
                ref.invalidate(activeBoatProvider);
                ref.invalidate(userSettingsProvider);

                messenger.showSnackBar(
                  SnackBar(content: Text('${boat.name} deleted successfully')),
                );
              } catch (e, st) {
                unawaited(
                    ErrorLogService().logException(e, st, context: 'boats_screen: delete boat'));
                messenger.showSnackBar(
                  SnackBar(content: Text('Error deleting boat: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class BoatListTile extends StatelessWidget {
  final Boat boat;
  final bool isActive;
  final bool isPro;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BoatListTile({
    super.key,
    required this.boat,
    required this.isActive,
    required this.isPro,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
          child: Icon(
            Icons.directions_boat,
            color: isActive ? Theme.of(context).colorScheme.onPrimary : Colors.white,
          ),
        ),
        title: Text(
          boat.name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: isActive ? const Text('Active Boat') : null,
        trailing: isPro
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
