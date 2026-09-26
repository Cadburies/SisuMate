import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../models/models.dart';
import '../../providers/recipe_provider.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (collections) {
          if (collections.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.collections_bookmark_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No collections yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                      'Tap + to group recipes into a themed list, e.g. "Boat Party Menu".',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: SisuColors.incompleteBackground,
                    child: const Icon(Icons.collections_bookmark,
                        color: Colors.white),
                  ),
                  title: Text(collection.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    '${collection.recipeSupabaseIds.length} recipe'
                    '${collection.recipeSupabaseIds.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: SisuColors.incompleteBackground,
                        onPressed: () =>
                            _showEditDialog(context, ref, collection),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () =>
                            _confirmDelete(context, ref, collection),
                      ),
                    ],
                  ),
                  onTap: () => context.push(
                      AppRoutes.collectionDetail,
                      extra: collection),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New collection',
        onPressed: () => _showEditDialog(context, ref, null),
        backgroundColor: SisuColors.completedBackground,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, RecipeCollection? existing) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AddEditCollectionDialog(
        existing: existing,
        onSave: (name) async {
          final repo = ref.read(collectionRepositoryProvider);
          if (existing == null) {
            await repo.addCollection(RecipeCollection()..name = name);
          } else {
            await repo.updateCollection(existing..name = name);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, RecipeCollection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text('Remove "${collection.name}"? The recipes themselves are not deleted.'),
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
      await ref.read(collectionRepositoryProvider).deleteCollection(collection);
    }
  }
}

/// Create / rename collection (public for widget tests).
class AddEditCollectionDialog extends StatefulWidget {
  final RecipeCollection? existing;
  final Future<void> Function(String name) onSave;

  const AddEditCollectionDialog({
    super.key,
    this.existing,
    required this.onSave,
  });

  @override
  State<AddEditCollectionDialog> createState() =>
      _AddEditCollectionDialogState();
}

class _AddEditCollectionDialogState extends State<AddEditCollectionDialog> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final navigator = Navigator.of(context);
    await widget.onSave(name);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'New Collection' : 'Rename Collection',
      ),
      content: TextField(
        controller: _nameCtrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'e.g. Boat Party Menu',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.existing == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

class CollectionDetailScreen extends ConsumerWidget {
  final RecipeCollection collection;
  const CollectionDetailScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final currentCollection = collectionsAsync.asData?.value
            .where((c) => c.id == collection.id)
            .firstOrNull ??
        collection;
    final menuRecipesAsync = ref.watch(recipesProvider('menu'));
    final cocktailRecipesAsync = ref.watch(recipesProvider('cocktail'));

    return Scaffold(
      appBar: AppBar(title: Text(currentCollection.name)),
      body: menuRecipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (menuRecipes) => cocktailRecipesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (cocktailRecipes) {
            final allRecipes = [...menuRecipes, ...cocktailRecipes];
            final byId = {for (final r in allRecipes) r.supabaseId: r};
            final recipes = currentCollection.recipeSupabaseIds
                .map((id) => byId[id])
                .whereType<Recipe>()
                .toList();

            if (recipes.isEmpty) {
              return Center(
                child: Text('No recipes yet. Tap + to add one.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline)),
              );
            }
            return ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return ListTile(
                  leading: Icon(
                    recipe.recipeType == 'cocktail'
                        ? Icons.local_bar_outlined
                        : Icons.restaurant_menu,
                    color: SisuColors.incompleteBackground,
                  ),
                  title: Text(recipe.name),
                  subtitle: recipe.cuisine.isNotEmpty
                      ? Text(recipe.cuisine.join(' · '))
                      : null,
                  trailing: IconButton(
                    icon: Icon(Icons.close,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () async {
                      final updated = currentCollection
                        ..recipeSupabaseIds = currentCollection.recipeSupabaseIds
                            .where((id) => id != recipe.supabaseId)
                            .toList();
                      await ref
                          .read(collectionRepositoryProvider)
                          .updateCollection(updated);
                    },
                  ),
                  onTap: () => context.push(
                    recipe.recipeType == 'cocktail'
                        ? AppRoutes.cocktailRecipe
                        : AppRoutes.chefRecipe,
                    extra: recipe,
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add recipes',
        onPressed: () => _showRecipePicker(context, ref, currentCollection),
        backgroundColor: SisuColors.completedBackground,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRecipePicker(
      BuildContext context, WidgetRef ref, RecipeCollection currentCollection) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Consumer(
          builder: (context, ref, _) {
            final menuRecipesAsync = ref.watch(recipesProvider('menu'));
            final cocktailRecipesAsync = ref.watch(recipesProvider('cocktail'));
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text('Add a recipe',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: menuRecipesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (menuRecipes) => cocktailRecipesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (cocktailRecipes) {
                          final available = [...menuRecipes, ...cocktailRecipes]
                              .where((r) => !currentCollection.recipeSupabaseIds
                                  .contains(r.supabaseId))
                              .toList();
                          if (available.isEmpty) {
                            return Center(
                              child: Text('All recipes are already in this collection.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: available.length,
                            itemBuilder: (context, index) {
                              final recipe = available[index];
                              return ListTile(
                                leading: Icon(
                                  recipe.recipeType == 'cocktail'
                                      ? Icons.local_bar_outlined
                                      : Icons.restaurant_menu,
                                  color: SisuColors.incompleteBackground,
                                ),
                                title: Text(recipe.name),
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  final updated = currentCollection
                                    ..recipeSupabaseIds = [
                                      ...currentCollection.recipeSupabaseIds,
                                      recipe.supabaseId,
                                    ];
                                  await ref
                                      .read(collectionRepositoryProvider)
                                      .updateCollection(updated);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
