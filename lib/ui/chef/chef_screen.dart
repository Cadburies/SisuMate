import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../components/title_tile.dart';
import '../components/tag_chip.dart';
import '../components/common_drawer.dart';
import '../components/swipeable_list_item.dart';
import '../components/sisu_tile_card.dart';
import '../components/themed_state_tile.dart';
import '../components/ingredient_list_sort.dart';
import '../components/photo_source_picker.dart';
import '../components/native_ad_widget.dart';
import '../components/ad_slots.dart';
import '../cocktails/cocktails_screen.dart' show AddEditRecipeArgs;
import '../../providers/recipe_provider.dart';
import '../../providers/pantry_ingredient_provider.dart';
import '../../providers/shopping_provider.dart';
import '../components/import_export.dart';
import '../../services/error_log_service.dart';
import '../../services/import_service.dart';
import '../../services/revenuecat_service.dart';
import '../../services/mixologist_service.dart';
import '../../services/seasonal_service.dart';
import '../../services/recipe_allergen_service.dart';
import '../../services/calorie_calculator.dart';
import '../../services/recipe_share_service.dart';
import '../../services/recipe_import_service.dart';
import '../../services/quantity_model.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../../models/models.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../core/units.dart';
import '../../services/tag_library_service.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _allergens = [
  'gluten', 'dairy', 'eggs', 'nuts', 'peanuts', 'shellfish',
  'fish', 'soy', 'sesame', 'sulphites', 'mustard', 'celery',
  'lupin', 'molluscs',
];

const _dietaryTags = [
  'vegan', 'vegetarian', 'gluten-free', 'dairy-free', 'egg-free',
  'nut-free', 'keto', 'paleo', 'halal', 'kosher', 'low-carb', 'low-sodium',
];

const _cuisineCocktailKeywords = <String, List<String>>{
  'mediterranean': ['negroni', 'campari', 'gin', 'spritz', 'aperol', 'limoncello', 'vermouth'],
  'asian': ['sour', 'ginger', 'lychee', 'yuzu', 'sake', 'plum', 'jasmine'],
  'french': ['french 75', 'sidecar', 'kir', 'champagne', 'cognac', 'cointreau'],
  'italian': ['negroni', 'aperol', 'spritz', 'campari', 'amaretto', 'limoncello', 'bellini'],
  'caribbean': ['rum', 'daiquiri', 'mojito', 'mai tai', 'zombie', 'jungle bird', 'hurricane', 'piña colada'],
  'australian': ['sour', 'gin', 'bourbon', 'lager'],
  'spanish': ['gin', 'sherry', 'cava', 'tinto', 'sangria'],
  'japanese': ['whisky', 'highball', 'yuzu', 'sake', 'sour'],
  'american': ['bourbon', 'manhattan', 'old fashioned', 'whiskey', 'sour'],
  'thai': ['coconut', 'rum', 'mango', 'lychee', 'ginger', 'sour'],
};

const _chefVibes = [
  'italian', 'asian', 'mediterranean', 'light',
  'hearty', 'comfort', 'fresh', 'spicy', 'umami', 'sweet & savory',
];

// ── Root screen ───────────────────────────────────────────────────────────────

class ChefScreen extends ConsumerStatefulWidget {
  const ChefScreen({super.key});

  @override
  ConsumerState<ChefScreen> createState() => _ChefScreenState();
}

class _ChefScreenState extends ConsumerState<ChefScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  /// My Pantry list sort (drawer). Sticky order until sort mode changes.
  final IngredientListOrder _pantryOrder = IngredientListOrder();

  bool _didSyncMissing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    // Seeded recipes default missingIngredientCount=0; recompute against
    // My Pantry (#157 — mirrors Cocktails' same recompute-on-load).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didSyncMissing) return;
      _didSyncMissing = true;
      await ref.read(recipeRepositoryProvider).syncMissingIngredientCounts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _exportRecipes(List<Recipe> recipes) async {
    final repo = ref.read(recipeRepositoryProvider);
    final imported = <ImportedRecipe>[];
    for (final r in recipes) {
      imported.add(
          ImportedRecipe(r, await repo.getIngredientsOnce(r.supabaseId)));
    }
    return ImportService.exportRecipes(
      imported,
      unitSystem: ref.read(unitSystemProvider),
    );
  }

  Future<ImportPersistResult> _importRecipes(
      ImportBatch batch, String recipeType) async {
    final repo = ref.read(recipeRepositoryProvider);
    final existing = await repo.watchRecipes().first;
    var inserted = 0;
    var updated = 0;
    for (final ir in batch.recipes) {
      // Force the type to the screen the user is importing on, so a generic
      // recipe file lands where expected (Chef → menu, Cocktails → cocktail).
      ir.recipe.recipeType = recipeType;
      final match = ImportService.matchExisting(
        existing: existing,
        incomingId: ir.recipe.supabaseId,
        idOf: (e) => e.supabaseId,
        contentKeyOf: ImportService.contentKeyRecipe,
        incomingContentKey: ImportService.contentKeyRecipe(ir.recipe),
      );
      if (match != null) {
        ir.recipe.supabaseId = match.supabaseId;
        ir.recipe.id = match.id;
        await repo.updateRecipe(ir.recipe);
        final oldIngs = await repo.getIngredientsOnce(match.supabaseId);
        for (final o in oldIngs) {
          await repo.deleteIngredient(o);
        }
        for (final ing in ir.ingredients) {
          ing.recipeSupabaseId = match.supabaseId;
          await repo.addIngredient(ing);
        }
        updated++;
      } else {
        await repo.addRecipe(ir.recipe);
        for (final ing in ir.ingredients) {
          await repo.addIngredient(ing);
        }
        existing.add(ir.recipe);
        inserted++;
      }
    }
    await repo.syncMissingIngredientCounts();
    return ImportPersistResult(inserted: inserted, updated: updated);
  }

  /// #340: off-screen TabBarView pages still participate in Android hit-testing
  /// and focus. Ignore pointers + exclude focus on inactive tabs so a tap on
  /// My Pantry cannot land on Chef's search field (or vice versa).
  Widget _gatedTab(int index, Widget child) {
    final active = _tabController.index == index;
    return ExcludeFocus(
      excluding: !active,
      child: IgnorePointer(ignoring: !active, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final isPro = isProAsync.value ?? false;
    final menuRecipes =
        ref.watch(recipesProvider('menu')).value ?? const <Recipe>[];

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Chef',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                actionsBuilder: _tabController.index == 0
                    ? (color) => [
                          IconButton(
                            icon: Icon(Icons.import_export, color: color),
                            tooltip: 'Import / Export recipes',
                            onPressed: () => showImportExportSheet(
                              context,
                              ModuleImportExport(
                                kind: ImportService.kindRecipe,
                                label: 'Chef Recipes',
                                fileBaseName: 'sisu_recipes',
                                exportCurrent: () =>
                                    _exportRecipes(menuRecipes),
                                existingNames: () async =>
                                    menuRecipes.map((r) => r.name).toList(),
                                persist: (batch) =>
                                    _importRecipes(batch, 'menu'),
                              ),
                              isPro: isPro,
                              onProRequired: () =>
                                  RevenueCatService().showPaywall(context),
                              ref: ref,
                            ),
                          ),
                        ]
                    : null,
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.restaurant_menu), text: 'Chef'),
                  Tab(icon: Icon(Icons.kitchen), text: 'My Pantry'),
                  Tab(icon: Icon(Icons.auto_fix_high), text: "Chef's Corner"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _gatedTab(
                      0,
                      _ChefTab(
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        onSearchChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                      ),
                    ),
                    _gatedTab(1, _PantryTab(order: _pantryOrder)),
                    _gatedTab(2, const _ChefsCornerTab()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 2
          ? null
          : isProAsync.when(
              data: (isPro) {
                if (_tabController.index == 0) {
                  return FloatingActionButton(
                    heroTag: 'menu_fab',
                    onPressed: () => isPro
                        ? _showAddRecipeOptions(context)
                        : _showProRequiredDialog(context),
                    child: const Icon(Icons.add),
                  );
                }
                return FloatingActionButton(
                  heroTag: 'pantry_fab',
                  onPressed: () => isPro
                      ? _showAddPantryIngredientDialog(context)
                      : _showProRequiredDialog(context,
                          feature: 'custom pantry ingredients'),
                  tooltip: 'Add custom ingredient',
                  child: const Icon(Icons.add),
                );
              },
              loading: () => const FloatingActionButton(
                  onPressed: null, child: CircularProgressIndicator()),
              error: (e, _) => const FloatingActionButton(
                  onPressed: null, child: Icon(Icons.error)),
            ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Consumer(
            builder: (context, ref, _) => Column(
              children: [
                DrawerHeaderWidget(title: 'Menu'),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Divider(),
                        ListTile(
                          leading:
                              const Icon(Icons.collections_bookmark_outlined),
                          title: const Text('Collections'),
                          onTap: () => context.push(AppRoutes.collections),
                        ),
                        // #137: only shown on My Pantry — it's the only tab
                        // that reads _pantryOrder, so it silently no-op'd
                        // elsewhere.
                        if (_tabController.index == 1) ...[
                          const Divider(),
                          SectionHeader(title: 'My Pantry sort'),
                          for (final mode in IngredientListSort.values)
                            ListTile(
                              dense: true,
                              leading: Icon(
                                _pantryOrder.sort == mode
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                              ),
                              title: Text(mode.label,
                                  style: const TextStyle(fontSize: 14)),
                              onTap: () {
                                setState(() => _pantryOrder.setSort(mode));
                                Navigator.of(context).pop();
                              },
                            ),
                        ],
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
      ),
    );
  }

  void _showProRequiredDialog(BuildContext context,
      {String feature = 'custom menus'}) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sisu Mate Pro Required'),
        content: Text(
            'Creating $feature is a Pro feature. Upgrade to unlock editing and unlimited entries.'),
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

  void _showAddRecipeOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Add manually'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showAddRecipeDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Import from URL'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showImportFromUrlDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecipeDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    context.push(
      AppRoutes.recipeEditor,
      extra: AddEditRecipeArgs(
        recipeType: RecipeType.menu,
        onSave: (recipe, ingredients, removedIngredients) async {
          final repo = ref.read(recipeRepositoryProvider);
          await repo.addRecipe(recipe);
          for (final ingredient in ingredients) {
            await repo.addIngredient(ingredient);
          }
          if (mounted) {
            navigator.pop();
            messenger.showSnackBar(
                SnackBar(content: Text('${recipe.name} added')));
          }
        },
      ),
    );
  }

  void _showImportFromUrlDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final urlController = TextEditingController();
    bool isLoading = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Import Recipe from URL'),
          content: TextField(
            controller: urlController,
            autofocus: true,
            keyboardType: TextInputType.url,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Recipe URL',
              hintText: 'https://example.com/recipe',
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (urlController.text.trim().isEmpty) {
                        messenger.showSnackBar(
                            const SnackBar(content: Text('Enter a URL first')));
                        return;
                      }
                      setState(() => isLoading = true);
                      try {
                        final parsed = await RecipeImportService.importFromUrl(
                            urlController.text);
                        final boatId =
                            (await ref.read(activeBoatProvider.future))
                                ?.supabaseId;
                        if (boatId != null && boatId.isNotEmpty) {
                          parsed.recipe.boatSupabaseId = boatId;
                        }
                        final repo = ref.read(recipeRepositoryProvider);
                        await repo.addRecipe(parsed.recipe);
                        for (final ingredient in parsed.ingredients) {
                          await repo.addIngredient(ingredient);
                        }
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        messenger.showSnackBar(SnackBar(
                            content: Text(
                                'Imported "${parsed.recipe.name}" — ${parsed.ingredients.length} ingredients')));
                      } on RecipeImportException catch (e) {
                        // Usually an expected "that URL/page doesn't work"
                        // outcome, but still worth a warning-level signal —
                        // a spike on one fingerprint means a previously
                        // working recipe site's markup changed.
                        unawaited(ErrorLogService().logWarning(
                          e.message,
                          context: 'chef_screen: recipe import (RecipeImportException)',
                        ));
                        setState(() => isLoading = false);
                        messenger.showSnackBar(SnackBar(content: Text(e.message)));
                      } catch (e, st) {
                        unawaited(ErrorLogService().logException(e, st,
                            context: 'chef_screen: recipe import (unexpected)'));
                        setState(() => isLoading = false);
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Something went wrong importing that recipe')));
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPantryIngredientDialog(BuildContext context) {
    _showPantryIngredientEditDialog(context, null);
  }
}

// ── Chef tab ─────────────────────────────────────────────────────────────────

class _ChefTab extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _ChefTab({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  ConsumerState<_ChefTab> createState() => _ChefTabState();
}

class _ChefTabState extends ConsumerState<_ChefTab> {
  String? _cuisineFilter;
  String? _methodFilter;
  String? _timeFilter; // '≤20', '≤45', or null
  bool _favouritesOnly = false;
  // #137: Chef had no sort of any kind; a simple local A-Z/Z-A toggle
  // matches the level of functionality My Pantry already has.
  bool _sortAscending = true;

  /// Ad slots for the recipe grid (stable across rebuilds; see ad_slots.dart).
  final NativeAdSlotCache _adSlotCache = NativeAdSlotCache();
  List<String> _cuisineChipOptions = List.of(TagLibraryService.suggestedCuisine);

  static const _methods = [
    'Grill', 'Stovetop', 'Wok', 'Oven', 'One-pot', 'Raw / No-cook', 'Pan-fry',
  ];

  @override
  void initState() {
    super.initState();
    TagLibraryService.instance.options(TagKind.cuisine).then((v) {
      if (mounted) setState(() => _cuisineChipOptions = v);
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: 'Search menus...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: widget.onSearchChanged,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Favourites'),
                avatar: const Icon(Icons.favorite, size: 16),
                selected: _favouritesOnly,
                selectedColor: Colors.red.withValues(alpha: 0.15),
                checkmarkColor: Colors.red,
                onSelected: (v) => setState(() => _favouritesOnly = v),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              ActionChip(
                avatar: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
                label: Text(_sortAscending ? 'Name A–Z' : 'Name Z–A'),
                onPressed: () =>
                    setState(() => _sortAscending = !_sortAscending),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        // Cuisine / course filter chips (suggested + user library + used on menus)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final c in _cuisineChipOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    selected: _cuisineFilter == c,
                    onSelected: (v) =>
                        setState(() => _cuisineFilter = v ? c : null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Method + time filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              for (final m in _methods)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(m, style: const TextStyle(fontSize: 12)),
                    selected: _methodFilter == m,
                    onSelected: (v) =>
                        setState(() => _methodFilter = v ? m : null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('≤ 20 min', style: TextStyle(fontSize: 12)),
                  selected: _timeFilter == '≤20',
                  onSelected: (v) =>
                      setState(() => _timeFilter = v ? '≤20' : null),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              FilterChip(
                label: const Text('≤ 45 min', style: TextStyle(fontSize: 12)),
                selected: _timeFilter == '≤45',
                onSelected: (v) =>
                    setState(() => _timeFilter = v ? '≤45' : null),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider('menu'));
    final headerSliver =
        SliverToBoxAdapter(child: _buildHeader(context));

    return recipesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading menus: $e')),
      data: (recipes) {
        var filtered = widget.searchQuery.isEmpty
            ? recipes
            : recipes
                .where((r) =>
                    r.name.toLowerCase().contains(widget.searchQuery) ||
                    (r.description
                            ?.toLowerCase()
                            .contains(widget.searchQuery) ??
                        false))
                .toList();
        if (_favouritesOnly) {
          filtered = filtered.where((r) => r.isFavourite).toList();
        }
        if (_cuisineFilter != null) {
          filtered = filtered
              .where((r) => r.cuisine.contains(_cuisineFilter))
              .toList();
        }
        if (_methodFilter != null) {
          filtered = filtered
              .where((r) => r.cookingMethod == _methodFilter)
              .toList();
        }
        if (_timeFilter != null) {
          final maxMin = _timeFilter == '≤20' ? 20 : 45;
          filtered = filtered.where((r) {
            final total = (r.prepMinutes ?? 0) + (r.cookMinutes ?? 0);
            return total <= maxMin;
          }).toList();
        }
        filtered = List.of(filtered)
          ..sort((a, b) => _sortAscending
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : b.name.toLowerCase().compareTo(a.name.toLowerCase()));

        // Empty filtered list still scrolls so filters remain reachable.
        if (filtered.isEmpty) {
          return CustomScrollView(
            slivers: [
              headerSliver,
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No menus match your filters.')),
                ),
              ),
            ],
          );
        }

        // #311 — Pro must not reserve grid cells for ads (shrink ≠ remove cell).
        final isPro = ref.watch(isProProvider).value ?? false;
        final slots =
            _adSlotCache.forList(filtered.length, showAds: !isPro);
        final count = filtered.length + slots.length;
        return CustomScrollView(
          slivers: [
            headerSliver,
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.48,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (isNativeAdSlot(i, slots)) {
                      return const NativeAdWidget(
                          style: NativeAdTileStyle.cocktailTile,
                          contextHint: 'chef');
                    }
                    return _RecipeCard(
                        recipe: filtered[nativeAdContentIndex(i, slots)]);
                  },
                  childCount: count,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync =
        ref.watch(recipeIngredientsProvider(recipe.supabaseId));
    final pantryAsync = ref.watch(pantryIngredientsProvider);

    final count = ingredientsAsync.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (e, _) => 0,
    );

    // Derive allergen tags (union) and dietary badges (intersection) from matched pantry ingredients
    final allergens = <String>{};
    final dietaryBadges = <String>[];
    ingredientsAsync.whenData((ingredients) {
      pantryAsync.whenData((pantryList) {
        final assessment = RecipeAllergenService.assess(ingredients, pantryList);
        allergens.addAll(assessment.allergens);
        dietaryBadges.addAll(assessment.dietaryBadges.take(2));
      });
    });

    final flavorColor = Colors.orange[700]!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.chefRecipe,
          extra: recipe,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.restaurant, size: 32, color: Colors.amber),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      recipe.isFavourite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: recipe.isFavourite ? Colors.red : Colors.white,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ],
                    ),
                    onPressed: () async {
                      recipe.isFavourite = !recipe.isFavourite;
                      await ref
                          .read(recipeRepositoryProvider)
                          .updateRecipe(recipe);
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                // #225: up to 6 optional sections (chips/count/time/
                // allergens/dietary badges) can stack for a fully-tagged
                // recipe and exceed the grid cell's fixed height —
                // scrollable rather than a bare Column so that combination
                // never hard-overflows (same fix shape as #160/#178).
                child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: SisuColors.getTextPrimaryColor(
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recipe.cuisine.isNotEmpty ||
                        recipe.flavorProfiles.isNotEmpty ||
                        recipe.cookingMethod != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (final c in recipe.cuisine.take(2))
                            _MiniChip(
                                label: c,
                                color: SisuColors.completedBackground),
                          for (final f in recipe.flavorProfiles.take(2))
                            _MiniChip(label: f, color: flavorColor),
                          if (recipe.cookingMethod != null)
                            _MiniChip(
                                label: recipe.cookingMethod!,
                                color: flavorColor),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '$count ingredients',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SisuColors.incompleteBackground,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (recipe.prepMinutes != null ||
                        recipe.cookMinutes != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (recipe.prepMinutes != null)
                            '${recipe.prepMinutes}m prep',
                          if (recipe.cookMinutes != null)
                            '${recipe.cookMinutes}m cook',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SisuColors.getTextSecondaryColor(
                                Theme.of(context).brightness ==
                                    Brightness.dark,
                              ),
                            ),
                      ),
                    ],
                    if (allergens.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 12,
                              color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              allergens.take(3).join(', '),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.error),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (dietaryBadges.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: dietaryBadges
                            .map((badge) => _MiniChip(
                                  label: badge,
                                  color: const Color(0xFF2e7d32),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Menu detail ───────────────────────────────────────────────────────────────

// #157: mirrors Cocktails' _missingRecipeIngredients — non-garnish,
// non-optional ingredients not in My Pantry, shared by the live count and
// "Add missing to shopping".
List<RecipeIngredient> _missingRecipeIngredientsPantry(
  List<RecipeIngredient> ingredients,
  List<PantryIngredient> pantryIngredients,
) {
  final pantryNames = pantryIngredients
      .where((p) => p.inMyPantry)
      .map((p) => p.name.toLowerCase().trim())
      .toSet();
  return ingredients
      .where(
        (i) =>
            !i.isGarnish &&
            !i.isOptional &&
            !pantryNames.contains(i.name.toLowerCase().trim()),
      )
      .toList();
}

class ChefRecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const ChefRecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<ChefRecipeDetailScreen> createState() =>
      ChefRecipeDetailScreenState();
}

class ChefRecipeDetailScreenState extends ConsumerState<ChefRecipeDetailScreen> {
  int _servings = 1;

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync =
        ref.watch(recipeIngredientsProvider(widget.recipe.supabaseId));
    final pantryAsync = ref.watch(pantryIngredientsProvider);
    final cocktailsAsync = ref.watch(recipesProvider('cocktail'));
    final isProAsync = ref.watch(isProProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (tileContext) => TitleTile(
                title: widget.recipe.name,
                onMenuPressed: () =>
                    Scaffold.of(tileContext).openEndDrawer(),
                actionsBuilder: (iconColor) => [
                  IconButton(
                    icon: Icon(
                      widget.recipe.isFavourite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.recipe.isFavourite
                          ? Colors.red
                          : iconColor,
                    ),
                    tooltip: 'Favourite',
                    onPressed: () async {
                      widget.recipe.isFavourite =
                          !widget.recipe.isFavourite;
                      await ref
                          .read(recipeRepositoryProvider)
                          .updateRecipe(widget.recipe);
                      if (mounted) setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.ios_share, color: iconColor),
                    tooltip: 'Print / Share',
                    onPressed: () => ingredientsAsync.whenData((ingredients) =>
                        RecipeShareService.shareRecipeCard(
                            recipe: widget.recipe, ingredients: ingredients)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.recipe.description != null) ...[
                      Text(widget.recipe.description!,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 12),
                    ],
                    if (widget.recipe.prepMinutes != null ||
                        widget.recipe.cookMinutes != null) ...[
                      Wrap(
                        spacing: 8,
                        children: [
                          if (widget.recipe.prepMinutes != null)
                            Chip(
                              avatar: const Icon(Icons.schedule, size: 14),
                              label:
                                  Text('Prep ${widget.recipe.prepMinutes} min'),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (widget.recipe.cookMinutes != null)
                            Chip(
                              avatar: const Icon(
                                  Icons.local_fire_department,
                                  size: 14),
                              label:
                                  Text('Cook ${widget.recipe.cookMinutes} min'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text('Ingredients',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    // Match cocktails: 1–12 chips in a Wrap (no horizontal overflow).
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Servings:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final n in const [1, 2, 4, 6, 8, 10, 12])
                              ChoiceChip(
                                label: Text('$n'),
                                selected: _servings == n,
                                onSelected: (_) =>
                                    setState(() => _servings = n),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ingredientsAsync.when(
                      data: (ingredients) {
                        // Estimated cost per serving × servings
                        double? totalCost;
                        RecipeCalorieSummary? calorieSummary;
                        pantryAsync.whenData((pantryList) {
                          totalCost = const QuantityModel().recipePackCost(
                            ingredients: ingredients,
                            pantry: pantryList,
                            servings: _servings,
                          );
                          calorieSummary =
                              CalorieCalculator.compute(ingredients, pantryList);
                        });
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...ingredients.map((i) =>
                                _PantryIngredientAvailabilityTile(
                                    ingredient: i,
                                    servingsMultiplier: _servings)),
                            if (totalCost != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.attach_money,
                                      size: 16, color: SisuColors.completedBackground),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Est. cost: \$${totalCost!.toStringAsFixed(2)} for $_servings serving${_servings == 1 ? '' : 's'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: SisuColors.completedBackground),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (calorieSummary?.totalCalories != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      size: 16, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Est. calories: ~${(calorieSummary!.totalCalories! * _servings).round()} kcal '
                                      'for $_servings serving${_servings == 1 ? '' : 's'} '
                                      '(${calorieSummary!.computedCount}/${calorieSummary!.totalCount} ingredients)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.orange[800]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    if (ingredientsAsync.asData != null &&
                        pantryAsync.asData != null)
                      Builder(
                        builder: (_) {
                          final missing = _missingRecipeIngredientsPantry(
                            ingredientsAsync.asData!.value,
                            pantryAsync.asData!.value,
                          );
                          if (missing.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  size: 16,
                                ),
                                label: Text(
                                  'Add ${missing.length} missing to shopping',
                                ),
                                onPressed: () => _addMissingToShopping(
                                  context,
                                  ingredientsAsync.asData!.value,
                                  pantryAsync.asData!.value,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    if (widget.recipe.instructions != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Instructions',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                          ),
                          FilledButton.icon(
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Cook'),
                            style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact),
                            onPressed: () => context.push(
                              AppRoutes.chefCookingMode,
                              extra: (
                                recipeName: widget.recipe.name,
                                instructions:
                                    UnitConverter.convertTemperaturesInText(
                                  widget.recipe.instructions!,
                                  ref.read(unitSystemProvider),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(UnitConverter.convertTemperaturesInText(
                        widget.recipe.instructions!,
                        ref.watch(unitSystemProvider),
                      )),
                    ],
                    // #214: curated wine + cocktail suggestions — distinct
                    // from the "Pairs well with" section below, which
                    // cross-references this app's own cocktail catalog by
                    // keyword rather than a specifically chosen pairing.
                    if (widget.recipe.winePairing != null ||
                        widget.recipe.cocktailPairing != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Suggested Pairing',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.recipe.winePairing != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.wine_bar,
                                      size: 18, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.recipe.winePairing!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.recipe.winePairing != null &&
                                widget.recipe.cocktailPairing != null)
                              const SizedBox(height: 8),
                            if (widget.recipe.cocktailPairing != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.local_bar,
                                      size: 18, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.recipe.cocktailPairing!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                    // Leftover ideas (CF8)
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => _showLeftoverIdeas(
                        context,
                        pantryAsync.asData?.value ?? [],
                      ),
                      icon: const Icon(Icons.kitchen_outlined),
                      label: const Text('Got Leftovers? Get Ideas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SisuColors.completedBackground,
                        side: BorderSide(
                          color: SisuColors.completedBackground.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                    // Drink pairing (CF10)
                    Builder(builder: (context) {
                      final keywords = <String>{};
                      for (final tag in widget.recipe.cuisine) {
                        final list =
                            _cuisineCocktailKeywords[tag.toLowerCase().trim()];
                        if (list != null) keywords.addAll(list);
                      }
                      if (keywords.isEmpty) return const SizedBox.shrink();
                      final paired = cocktailsAsync.asData?.value
                              .where((c) => keywords.any((k) =>
                                  c.name.toLowerCase().contains(k)))
                              .take(3)
                              .toList() ??
                          [];
                      if (paired.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.local_bar,
                                  size: 18, color: Colors.deepPurple),
                              const SizedBox(width: 6),
                              Text('Pairs well with',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.deepPurple)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: paired
                                .map((c) => Chip(
                                      avatar: const Icon(Icons.local_bar,
                                          size: 14,
                                          color: Colors.deepPurple),
                                      label: Text(c.name,
                                          style: const TextStyle(fontSize: 12)),
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isProAsync.when(
        data: (isPro) => isPro
            ? FloatingActionButton(
                onPressed: () => _showEditDialog(context),
                child: const Icon(Icons.edit),
              )
            : null,
        loading: () => null,
        error: (e, _) => null,
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeaderWidget(title: 'Recipe options'),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit recipe'),
                        onTap: () {
                          Navigator.pop(context);
                          isProAsync.whenData((isPro) {
                            if (isPro) {
                              _showEditDialog(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Editing requires Sisu Mate Pro')),
                              );
                            }
                          });
                        },
                      ),
                      ListTile(
                        leading: Icon(widget.recipe.isFavourite
                            ? Icons.favorite
                            : Icons.favorite_border),
                        title: Text(widget.recipe.isFavourite
                            ? 'Remove favourite'
                            : 'Add favourite'),
                        onTap: () async {
                          Navigator.pop(context);
                          widget.recipe.isFavourite =
                              !widget.recipe.isFavourite;
                          await ref
                              .read(recipeRepositoryProvider)
                              .updateRecipe(widget.recipe);
                          if (mounted) setState(() {});
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.ios_share),
                        title: const Text('Print / Share'),
                        onTap: () {
                          Navigator.pop(context);
                          ingredientsAsync.whenData((ingredients) =>
                              RecipeShareService.shareRecipeCard(
                                  recipe: widget.recipe,
                                  ingredients: ingredients));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.sync),
                        title: const Text('Sync ingredient counts'),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref
                              .read(recipeRepositoryProvider)
                              .syncMissingIngredientCounts();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Ingredient counts updated'),
                                  duration: Duration(seconds: 1)),
                            );
                          }
                        },
                      ),
                      const Divider(),
                      SectionHeader(title: 'Account'),
                      AccountSection(),
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

  void _showLeftoverIdeas(BuildContext context, List<PantryIngredient> pantryIngredients) {
    final vibes = widget.recipe.cuisine
        .map((c) => c.toLowerCase().trim())
        .where((c) => _chefVibes.contains(c))
        .toList();
    final suggestion = MixologistService.suggestDish(
      vibes: vibes.isEmpty ? ['hearty'] : vibes,
      pantryIngredients: pantryIngredients,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              const Icon(Icons.kitchen_outlined, color: SisuColors.completedBackground),
              const SizedBox(width: 8),
              Text('Leftover Ideas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
            ]),
            const SizedBox(height: 4),
            Text(
              'What to make with what\'s left in your pantry',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const Divider(height: 24),
            if (suggestion == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No ideas yet — mark more ingredients as "In Pantry" to get suggestions.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              Text(suggestion.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 4),
              _MiniChip(label: suggestion.cuisine, color: SisuColors.completedBackground),
              const SizedBox(height: 12),
              Text(suggestion.rationale,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.outline,
                  )),
              if (suggestion.leftoverNotes.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...suggestion.leftoverNotes.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 14, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            n,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Ingredients',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...suggestion.ingredients.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Icon(Icons.fiber_manual_record,
                      size: 8, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${i.quantity > 0 ? "${i.quantity} ${i.unit}  " : ""}${i.name}'
                      '${i.optional ? "  (optional)" : ""}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ]),
              )),
              const SizedBox(height: 16),
              Text('Method',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(suggestion.instructions,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addMissingToShopping(
    BuildContext context,
    List<RecipeIngredient> ingredients,
    List<PantryIngredient> pantryIngredients,
  ) async {
    const model = QuantityModel();
    final byName = {
      for (final p in pantryIngredients) p.name.toLowerCase().trim(): p,
    };
    final repo = ref.read(shoppingRepositoryProvider);
    var addedCount = 0;
    for (final ingredient in ingredients) {
      final line = model.lineForRecipeIngredient(
        ingredient: ingredient,
        servings: _servings,
        pantry: byName[ingredient.name.toLowerCase().trim()],
      );
      if (line == null) continue;
      final added = await repo.ensurePacksInShopping(
        name: line.name,
        origin: 'pantry',
        packs: line.packages,
        merge: ShopPackMerge.setMin,
        unitOverride: line.unitLabel,
        priceOverride: line.pricePerPackage,
      );
      if (added) addedCount++;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            addedCount == 0
                ? 'All missing ingredients already on the shopping list'
                : '$addedCount pack line${addedCount == 1 ? '' : 's'} added to shopping',
          ),
        ),
      );
    }
  }

  void _showEditDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repo = ref.read(recipeRepositoryProvider);
    final existingIngredients = await repo.getIngredientsOnce(widget.recipe.supabaseId);
    if (!context.mounted) return;
    context.push(
      AppRoutes.recipeEditor,
      extra: AddEditRecipeArgs(
        recipeType: RecipeType.menu,
        existingRecipe: widget.recipe,
        existingIngredients: existingIngredients,
        onSave: (recipe, ingredients, removedIngredients) async {
          await repo.updateRecipe(recipe);
          for (final ingredient in ingredients) {
            await repo.addIngredient(ingredient);
          }
          for (final ingredient in removedIngredients) {
            await repo.deleteIngredient(ingredient);
          }
          if (mounted) {
            navigator.pop();
            messenger.showSnackBar(
                SnackBar(content: Text('${recipe.name} updated')));
          }
        },
      ),
    );
  }
}

// ── Step-by-step cooking mode ─────────────────────────────────────────────────

class CookingModeScreen extends StatefulWidget {
  final String recipeName;
  final String instructions;
  const CookingModeScreen(
      {super.key, required this.recipeName, required this.instructions});

  @override
  State<CookingModeScreen> createState() => CookingModeScreenState();
}

class CookingModeScreenState extends State<CookingModeScreen> {
  late final List<String> _steps;
  int _current = 0;

  // Per-step timer
  int _timerSeconds = 0;
  int _remainingSeconds = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    // Split on '. ' or newlines, filter blanks
    final raw = widget.instructions
        .split(RegExp(r'\.\s+|\n+'))
        .map((s) => s.trim().replaceAll(RegExp(r'^\d+[\.\)]\s*'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
    _steps = raw.isEmpty ? [widget.instructions] : raw;
  }

  @override
  void dispose() {
    _timerRunning = false;
    super.dispose();
  }

  void _startTimer() {
    if (_timerSeconds == 0) return;
    setState(() {
      _remainingSeconds = _timerSeconds;
      _timerRunning = true;
    });
    _tick();
  }

  void _tick() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || !_timerRunning) return;
    setState(() => _remainingSeconds--);
    if (_remainingSeconds > 0) {
      _tick();
    } else {
      setState(() => _timerRunning = false);
    }
  }

  void _goTo(int index) {
    setState(() {
      _current = index;
      _timerRunning = false;
      _timerSeconds = 0;
      _remainingSeconds = 0;
    });
  }

  String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_current];
    final total = _steps.length;
    final isLast = _current == total - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.recipeName,
            style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_current + 1) / total,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${_current + 1} of $total',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Step card
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        step.endsWith('.') ? step : '$step.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                                fontSize: 20,
                                height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Timer row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: 6),
                  _timerRunning || _remainingSeconds > 0
                      ? Text(
                          _fmt(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds == 0
                                ? SisuColors.completedBackground
                                : null,
                          ),
                        )
                      : SizedBox(
                          width: 64,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'min',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (v) {
                              final mins = int.tryParse(v) ?? 0;
                              setState(() => _timerSeconds = mins * 60);
                            },
                          ),
                        ),
                  const SizedBox(width: 8),
                  if (!_timerRunning && _timerSeconds > 0)
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      onPressed: _startTimer,
                    ),
                  if (_timerRunning)
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined),
                      onPressed: () =>
                          setState(() => _timerRunning = false),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _current > 0 ? () => _goTo(_current - 1) : null,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isLast
                        ? FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          )
                        : FilledButton(
                            onPressed: () => _goTo(_current + 1),
                            child: const Text('Next'),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Chef recipe detail ingredient row.
// Colour tells stock/shopping state (theme.md §6.5) — no status labels.
// Secondary line: quantity; tertiary: flavor profiles (+ allergens / optional).
class _PantryIngredientAvailabilityTile extends ConsumerWidget {
  final RecipeIngredient ingredient;
  final int servingsMultiplier;
  const _PantryIngredientAvailabilityTile({
    required this.ingredient,
    this.servingsMultiplier = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryAsync = ref.watch(pantryIngredientsProvider);
    final shoppingNames =
        ref.watch(shoppingItemNamesProvider).asData?.value ?? {};
    return pantryAsync.when(
      data: (pantryIngredients) {
        final nameLower = ingredient.name.toLowerCase().trim();
        // #186: every ingredient is physically in the pantry or not — no
        // separate "seeded catalog row" tier. A recipe ingredient that's
        // never been added yet is simply not in the pantry, same as one
        // that is in the catalog but unstocked.
        final inPantry = pantryIngredients.any((p) =>
            p.name.toLowerCase().trim() == nameLower && p.inMyPantry);
        final pantryIngredient = pantryIngredients
            .where((p) => p.name.toLowerCase().trim() == nameLower)
            .firstOrNull;
        final inShopping = shoppingNames.contains(nameLower);

        // Colour tells state — no bag/tick status icons, no stock prose.
        final ItemListState state;
        final IconData leadingIcon;
        if (ingredient.isGarnish) {
          state = ItemListState.hidden;
          leadingIcon = Icons.local_florist_outlined;
        } else if (inPantry) {
          state = ItemListState.stocked;
          leadingIcon = Icons.kitchen;
        } else if (inShopping) {
          state = ItemListState.shopping;
          leadingIcon = Icons.kitchen;
        } else {
          // #186: not in pantry reads the same (red/unavailable) whether or
          // not this exact name has ever been added to the pantry catalog.
          state = ItemListState.unavailable;
          leadingIcon = Icons.kitchen;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final c = SisuColors.itemStateColors(isDark, state);
        final unitSystem = ref.watch(unitSystemProvider);
        final qtyFormatted = UnitConverter.format(
          ingredient.quantity,
          ingredient.unit,
          unitSystem,
          scale: servingsMultiplier.toDouble(),
        );
        final qtyLine = qtyFormatted.isEmpty ? null : qtyFormatted;

        final profiles = pantryIngredient?.flavorProfiles ?? const <String>[];
        final flavorLine =
            profiles.isEmpty ? null : profiles.take(4).join(' · ');
        final allergens = pantryIngredient?.allergenTags ?? const <String>[];
        final allergenLine = allergens.isEmpty
            ? null
            : 'Contains: ${allergens.take(3).join(', ')}';

        final extra = <String>[
          ?flavorLine,
          ?allergenLine,
          if (ingredient.isOptional) 'Optional',
          if (ingredient.isGarnish && ingredient.garnishNotes != null)
            ingredient.garnishNotes!,
          if (!inPantry && ingredient.substitute != null)
            'Try: ${ingredient.substitute}',
        ];

        void openInPantry() {
          final list = pantryIngredients;
          final idx = list.indexWhere(
              (p) => p.name.toLowerCase().trim() == nameLower);
          if (idx < 0) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${ingredient.name} is not in My Pantry — swipe In Pantry to add it'),
              duration: const Duration(seconds: 2),
            ));
            return;
          }
          context.push(
            AppRoutes.pantryIngredientDetail,
            extra: (items: list, initialIndex: idx),
          );
        }

        final tile = ThemedStateTile(
          state: state,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          leading: Icon(leadingIcon, color: c.desc),
          title: ingredient.name,
          subtitle: qtyLine,
          tertiary: extra.isEmpty ? null : extra.join(' · '),
          onTap: ingredient.isGarnish ? null : openInPantry,
        );

        if (ingredient.isGarnish) return tile;

        return Slidable(
          key: ValueKey(ingredient.supabaseId),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (ctx) async {
                  final pantryList = pantryIngredients;
                  PantryIngredient? match;
                  for (final p in pantryList) {
                    if (p.name.toLowerCase().trim() ==
                        ingredient.name.toLowerCase().trim()) {
                      match = p;
                      break;
                    }
                  }
                  final line = const QuantityModel().lineForRecipeIngredient(
                    ingredient: ingredient,
                    servings: servingsMultiplier,
                    pantry: match,
                  );
                  final added = await ref
                      .read(shoppingRepositoryProvider)
                      .ensurePacksInShopping(
                        name: ingredient.name,
                        origin: 'pantry',
                        packs: line?.packages ?? 1,
                        merge: ShopPackMerge.setMin,
                        unitOverride: line?.unitLabel,
                        priceOverride: line?.pricePerPackage,
                      );
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(added
                          ? '${ingredient.name} added to shopping'
                          : '${ingredient.name} is already on the shopping list'),
                      duration: const Duration(seconds: 1),
                    ));
                  }
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.add_shopping_cart,
                label: 'Shopping',
              ),
            ],
          ),
          // #186: one physical toggle — in the pantry or not — regardless
          // of whether this ingredient already has a catalog row. If it
          // doesn't, the first tap creates it (transparently) already
          // marked in-pantry; that's still just "In Pantry", not a
          // separate "Track" action.
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (ctx) async {
                  if (pantryIngredient != null) {
                    await ref
                        .read(pantryIngredientRepositoryProvider)
                        .toggleInMyPantry(pantryIngredient);
                  } else {
                    final newIng = PantryIngredient()
                      ..supabaseId =
                          'pantry_custom_${nameLower.replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}'
                      ..name = ingredient.name
                      ..inMyPantry = true
                      ..isBundled = false;
                    await ref
                        .read(pantryIngredientRepositoryProvider)
                        .addPantryIngredient(newIng);
                  }
                },
                backgroundColor: SisuColors.completedBackground,
                foregroundColor: Colors.white,
                icon: inPantry ? Icons.remove_circle_outline : Icons.check,
                label: inPantry ? 'Remove' : 'In Pantry',
              ),
            ],
          ),
          child: tile,
        );
      },
      loading: () => ListTile(
          title: Text(ingredient.name),
          subtitle: const Text('Checking pantry...')),
      error: (e, _) =>
          ListTile(title: Text(ingredient.name), subtitle: Text('Error: $e')),
    );
  }
}

// ── My Pantry tab ─────────────────────────────────────────────────────────────

class _PantryTab extends ConsumerStatefulWidget {
  final IngredientListOrder order;
  const _PantryTab({required this.order});

  @override
  ConsumerState<_PantryTab> createState() => _PantryTabState();
}

class _PantryTabState extends ConsumerState<_PantryTab> {
  final TextEditingController _searchController = TextEditingController();
  final NativeAdSlotCache _adSlotCache = NativeAdSlotCache();
  String _searchQuery = '';
  int _lastSortEpoch = -1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantryAsync = ref.watch(pantryIngredientsProvider);
    final shoppingNames =
        ref.watch(shoppingItemNamesProvider).asData?.value ?? {};
    if (_lastSortEpoch != widget.order.sortEpoch) {
      _lastSortEpoch = widget.order.sortEpoch;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              hintText: 'Search pantry...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sorted: ${widget.order.sort.shortLabel}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ),
        Expanded(
          child: pantryAsync.when(
            data: (ingredients) {
              // Order full list (sticky); search only filters the view.
              final ordered = widget.order.apply(
                items: ingredients,
                idOf: (i) => i.supabaseId,
                nameOf: (i) => i.name,
                categoryOf: (i) => i.category,
                inStockOf: (i) => i.inMyPantry,
                inShoppingOf: (i) =>
                    shoppingNames.contains(i.name.toLowerCase().trim()),
              );
              final filtered = _searchQuery.isEmpty
                  ? ordered
                  : ordered
                      .where((i) =>
                          i.name.toLowerCase().contains(_searchQuery))
                      .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('No ingredients found.'));
              }
              // #311 — no ad indices when Pro (list shrink is fine; stay consistent).
              final isPro = ref.watch(isProProvider).value ?? false;
              final adSlots =
                  _adSlotCache.forList(filtered.length, showAds: !isPro);
              return Listener(
                onPointerDown: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                child: ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: filtered.length + adSlots.length,
                itemBuilder: (_, idx) {
                  if (isNativeAdSlot(idx, adSlots)) {
                    return const NativeAdWidget(contextHint: 'chef-pantry');
                  }
                  final ingredient =
                      filtered[nativeAdContentIndex(idx, adSlots)];
                  return _PantryIngredientTile(
                    key: ValueKey(ingredient.supabaseId),
                    ingredient: ingredient,
                    allIngredients: filtered,
                  );
                },
              ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _PantryIngredientTile extends ConsumerWidget {
  final PantryIngredient ingredient;
  final List<PantryIngredient> allIngredients;
  const _PantryIngredientTile({
    super.key,
    required this.ingredient,
    required this.allIngredients,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync =
        ref.watch(menuRecipesForIngredientProvider(ingredient.name));
    final shoppingNames =
        ref.watch(shoppingItemNamesProvider).asData?.value ?? {};

    final inPantry = ingredient.inMyPantry;
    final inShopping =
        shoppingNames.contains(ingredient.name.toLowerCase().trim());
    final state = inPantry
        ? ItemListState.stocked
        : inShopping
            ? ItemListState.shopping
            : ItemListState.defaults;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = SisuColors.itemStateColors(isDark, state);

    final menus = menusAsync.asData?.value ?? const <Recipe>[];
    final menuSubtitle = menusAsync.when(
      data: (list) => list.isEmpty
          ? 'Not used in any menu'
          : 'Used in ${list.length} menu${list.length == 1 ? '' : 's'}',
      loading: () => 'Loading…',
      error: (e, _) => '',
    );
    final unitSystem = ref.watch(unitSystemProvider);
    final qtyFormatted = UnitConverter.format(
      ingredient.quantity,
      ingredient.unit,
      unitSystem,
    );
    final qtyLabel = qtyFormatted.isEmpty ? null : qtyFormatted;
    final price = ingredient.lastKnownPrice != null
        ? '\$${ingredient.lastKnownPrice!.toStringAsFixed(0)}'
        : null;
    final expiry = ingredient.expiryDate != null
        ? _expiryLabel(ingredient.expiryDate!)
        : null;
    // #187: allergens/flavor get their own colored chips (matching recipe
    // tiles) below — quantity/expiry/price stay plain text, unchanged.
    final tertiary = [
      ?qtyLabel,
      ?expiry,
      ?price,
      if (inShopping && !inPantry) 'On shopping list',
    ].join(' · ');

    final leading = ingredient.localPhotoPath != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(ingredient.localPhotoPath!),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(Icons.kitchen, color: c.desc),
            ),
          )
        : Icon(Icons.kitchen, color: c.desc);

    return SwipeableListItem.ingredientItem(
      isActive: inPantry,
      isCustom: !ingredient.isBundled,
      isInShopping: inShopping,
      onToggleStatus: () => ref
          .read(pantryIngredientRepositoryProvider)
          .toggleInMyPantry(ingredient),
      onAddToShopping: () => _addToShopping(context, ref),
      onMarkShoppingDone: () => _markShoppingDone(context, ref),
      onDelete:
          ingredient.isBundled ? null : () => _confirmDelete(context, ref),
      child: SisuTileCard(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        color: c.bg,
        elevation: 3,
        child: InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            final idx = allIngredients
                .indexWhere((p) => p.supabaseId == ingredient.supabaseId);
            context.push(
              AppRoutes.pantryIngredientDetail,
              extra: (
                items: allIngredients,
                initialIndex: idx < 0 ? 0 : idx,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient.name,
                        style: TextStyle(
                          color: c.title,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  menuSubtitle,
                  style: TextStyle(color: c.desc, fontSize: 13),
                ),
                if (menus.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final recipe in menus.take(8))
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: Text(
                            recipe.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => context.push(
                            AppRoutes.chefRecipe,
                            extra: recipe,
                          ),
                        ),
                    ],
                  ),
                ],
                if (ingredient.allergenTags.isNotEmpty ||
                    ingredient.flavorProfiles.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      for (final a in ingredient.allergenTags)
                        TagChip(label: a, color: Colors.red[700]!),
                      for (final f in ingredient.flavorProfiles)
                        TagChip(label: f, color: Colors.orange[700]!),
                    ],
                  ),
                ],
                if (tertiary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tertiary,
                    style: TextStyle(color: c.desc, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToShopping(BuildContext context, WidgetRef ref) async {
    final added =
        await ref.read(shoppingRepositoryProvider).ensurePacksInShopping(
              name: ingredient.name,
              origin: 'pantry',
              packs: 1,
              merge: ShopPackMerge.increment,
            );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added
            ? '${ingredient.name} added to shopping list'
            : '${ingredient.name} is already on the shopping list'),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  Future<void> _markShoppingDone(BuildContext context, WidgetRef ref) async {
    final n = await ref
        .read(shoppingRepositoryProvider)
        .markPendingBoughtByName(ingredient.name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(n > 0
            ? '${ingredient.name} marked bought'
            : 'No pending shopping line for ${ingredient.name}'),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete ingredient?'),
        content: Text('Remove "${ingredient.name}" from the pantry list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SisuColors.notAvailableBackground,
              foregroundColor: SisuColors.dialogButtonOnColor,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(pantryIngredientRepositoryProvider)
          .deletePantryIngredient(ingredient);
    }
  }
}

String _expiryLabel(DateTime expiryDate) {
  final daysLeft = expiryDate.difference(DateTime.now()).inDays;
  if (daysLeft < 0) return 'Expired ${(-daysLeft)}d ago';
  if (daysLeft <= 7) return 'Expires in ${daysLeft}d';
  return 'Exp ${expiryDate.day}/${expiryDate.month}';
}

// ── Pantry ingredient edit dialog ────────────────────────────────────────────

void _showPantryIngredientEditDialog(
    BuildContext context, PantryIngredient? existing) {
  showDialog<void>(
    context: context,
    builder: (_) => _PantryIngredientEditDialog(existing: existing),
  );
}

class _PantryIngredientEditDialog extends ConsumerStatefulWidget {
  final PantryIngredient? existing;
  const _PantryIngredientEditDialog({this.existing});

  @override
  ConsumerState<_PantryIngredientEditDialog> createState() =>
      _PantryIngredientEditDialogState();
}

class _PantryIngredientEditDialogState
    extends ConsumerState<_PantryIngredientEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;
  late List<String> _selectedAllergens;
  late List<String> _selectedDietary;
  String? _localPhotoPath;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _qtyCtrl = TextEditingController(
        text: e?.quantity != null ? '${e!.quantity}' : '');
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    _priceCtrl = TextEditingController(
        text: e?.lastKnownPrice != null ? '${e!.lastKnownPrice}' : '');
    _imageCtrl = TextEditingController(text: e?.imageUrl ?? '');
    _selectedAllergens = List<String>.from(e?.allergenTags ?? []);
    _selectedDietary = List<String>.from(e?.dietaryTags ?? []);
    _localPhotoPath = e?.localPhotoPath;
    _expiryDate = e?.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked =
        await pickPhotoFromCameraOrGallery(context, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _localPhotoPath = picked.path);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final (qty, unit) = UnitConverter.normalizePair(
      double.tryParse(_qtyCtrl.text.trim()),
      _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
    );
    final price = double.tryParse(_priceCtrl.text.trim());
    final imageUrl =
        _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim();
    final repo = ref.read(pantryIngredientRepositoryProvider);
    final navigator = Navigator.of(context);

    if (widget.existing == null) {
      final ingredient = PantryIngredient()
        ..supabaseId =
            'pantry_custom_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}'
        ..name = name
        ..quantity = qty
        ..unit = unit
        ..lastKnownPrice = price
        ..localPhotoPath = _localPhotoPath
        ..imageUrl = imageUrl
        ..expiryDate = _expiryDate
        ..allergenTags = List<String>.from(_selectedAllergens)
        ..dietaryTags = List<String>.from(_selectedDietary)
        ..isBundled = false;
      await repo.addPantryIngredient(ingredient);
    } else {
      widget.existing!
        ..name = name
        ..quantity = qty
        ..unit = unit
        ..lastKnownPrice = price
        ..localPhotoPath = _localPhotoPath
        ..imageUrl = imageUrl
        ..expiryDate = _expiryDate
        ..allergenTags = List<String>.from(_selectedAllergens)
        ..dietaryTags = List<String>.from(_selectedDietary);
      await repo.updatePantryIngredient(widget.existing!);
    }
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.existing == null ? 'Add Pantry Item' : 'Edit Pantry Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Ingredient name'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Unit (g, ml, can…)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                  labelText: 'Price (USD)',
                  prefixText: '\$'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            if (_localPhotoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_localPhotoPath!),
                    height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_a_photo, size: 16),
                    label: Text(_localPhotoPath == null
                        ? 'Add photo'
                        : 'Change photo'),
                    onPressed: _pickPhoto,
                  ),
                ),
                if (_localPhotoPath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Remove photo',
                    onPressed: () => setState(() => _localPhotoPath = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _imageCtrl,
              decoration:
                  const InputDecoration(labelText: 'Image URL (optional)'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _expiryDate == null
                        ? 'No expiry date set'
                        : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _expiryDate != null &&
                              _expiryDate!.isBefore(DateTime.now())
                          ? Colors.red
                          : null,
                    ),
                  ),
                ),
                TextButton(
                  child: const Text('Set date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expiryDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 1)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() => _expiryDate = picked);
                    }
                  },
                ),
                if (_expiryDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    tooltip: 'Clear expiry',
                    onPressed: () => setState(() => _expiryDate = null),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Contains allergens',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: _allergens
                  .map((a) => FilterChip(
                        label: Text(a,
                            style: const TextStyle(fontSize: 11)),
                        selected: _selectedAllergens.contains(a),
                        selectedColor:
                            Colors.red.withValues(alpha: 0.25),
                        onSelected: (v) => setState(() => v
                            ? _selectedAllergens.add(a)
                            : _selectedAllergens.remove(a)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text('Dietary tags',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: _dietaryTags
                  .map((d) => FilterChip(
                        label: Text(d,
                            style: const TextStyle(fontSize: 11)),
                        selected: _selectedDietary.contains(d),
                        selectedColor:
                            Colors.green.withValues(alpha: 0.25),
                        onSelected: (v) => setState(() => v
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
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ── Chef's Corner tab ─────────────────────────────────────────────────────────

class _ChefsCornerTab extends ConsumerStatefulWidget {
  const _ChefsCornerTab();

  @override
  ConsumerState<_ChefsCornerTab> createState() => _ChefsCornerTabState();
}

class _ChefsCornerTabState extends ConsumerState<_ChefsCornerTab> {
  final Set<String> _vibes = {};
  final Set<String> _allergenRestrictions = {};
  final Set<String> _dietaryRequirements = {};
  DishSuggestion? _suggestion;
  bool _isGenerating = false;

  void _generate(List<PantryIngredient> pantryIngredients) {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _suggestion = null;
    });
    final result = MixologistService.suggestDish(
      vibes: _vibes.toList(),
      pantryIngredients: pantryIngredients,
      allergenRestrictions: _allergenRestrictions.toList(),
      dietaryRequirements: _dietaryRequirements.toList(),
    );
    setState(() {
      _suggestion = result;
      _isGenerating = false;
    });
  }

  void _loadProfile(GuestProfile profile) {
    setState(() {
      _allergenRestrictions
        ..clear()
        ..addAll(profile.allergenRestrictions);
      _dietaryRequirements
        ..clear()
        ..addAll(profile.dietaryRequirements);
    });
  }

  void _showProfilePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final profilesAsync = ref.watch(guestProfilesProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text('Load Guest Profile',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Flexible(
                  child: profilesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: $e'),
                    ),
                    data: (profiles) {
                      if (profiles.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No guest profiles yet. Manage profiles to add one.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: SisuColors.incompleteBackground,
                              child: Text(
                                profile.name.isNotEmpty
                                    ? profile.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(profile.name),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _loadProfile(profile);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Manage Profiles'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.guestProfiles);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveAsRecipe(BuildContext context, DishSuggestion s) {
    final ingredientList = s.ingredients
        .map((i) =>
            '${i.quantity > 0 ? "${i.quantity} ${i.unit} " : ""}${i.name}${i.optional ? " (optional)" : ""}')
        .join('\n');
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    context.push(
      AppRoutes.recipeEditor,
      extra: AddEditRecipeArgs(
        recipeType: RecipeType.menu,
        prefillName: s.name,
        prefillInstructions:
            '${s.instructions}\n\nIngredients:\n$ingredientList',
        onSave: (recipe, ingredients, removedIngredients) async {
          final repo = ref.read(recipeRepositoryProvider);
          await repo.addRecipe(recipe);
          for (final ingredient in ingredients) {
            await repo.addIngredient(ingredient);
          }
          if (mounted) {
            navigator.pop();
            messenger.showSnackBar(
                SnackBar(content: Text('${recipe.name} saved to Chef')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pantryAsync = ref.watch(pantryIngredientsProvider);

    return pantryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (pantryIngredients) {
        final inPantryCount = pantryIngredients.where((i) => i.inMyPantry).length;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.auto_fix_high, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Chef's Corner",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.mealPlanner),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Meal Planner'),
                  ),
                ],
              ),
              Text(
                '$inPantryCount pantry items available',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 12),

              // Seasonal highlights (CF9)
              Builder(builder: (context) {
                final inSeason = SeasonalService.getInSeasonNow();
                if (inSeason.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: SisuColors.completedBackground.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: SisuColors.completedBackground.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.eco_outlined,
                            size: 16, color: SisuColors.completedBackground),
                        const SizedBox(width: 6),
                        Text(
                          'In season — ${SeasonalService.currentMonthName}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: SisuColors.completedBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: inSeason
                            .map((name) => _MiniChip(
                                  label: name,
                                  color: SisuColors.completedBackground,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                );
              }),

              // Cuisine vibe selector
              Text('What cuisine are you feeling?',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _chefVibes
                    .map((v) => FilterChip(
                          label: Text(v,
                              style: const TextStyle(
                                  fontSize: 12,
                                  textBaseline: TextBaseline.alphabetic)),
                          selected: _vibes.contains(v),
                          selectedColor:
                              Colors.orange.withValues(alpha: 0.25),
                          onSelected: (sel) => setState(() =>
                              sel ? _vibes.add(v) : _vibes.remove(v)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Allergen restrictions
              Row(
                children: [
                  Expanded(
                    child: Text('I cannot eat (allergens):',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  TextButton.icon(
                    onPressed: () => _showProfilePicker(context),
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('Load Profile'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _allergens
                    .map((a) => FilterChip(
                          label: Text(a,
                              style: const TextStyle(fontSize: 11)),
                          selected: _allergenRestrictions.contains(a),
                          selectedColor:
                              Colors.red.withValues(alpha: 0.2),
                          checkmarkColor: Colors.red,
                          onSelected: (v) => setState(() => v
                              ? _allergenRestrictions.add(a)
                              : _allergenRestrictions.remove(a)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Dietary requirements
              Text('Dietary preferences:',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _dietaryTags
                    .map((d) => FilterChip(
                          label: Text(d,
                              style: const TextStyle(fontSize: 11)),
                          selected: _dietaryRequirements.contains(d),
                          selectedColor:
                              Colors.green.withValues(alpha: 0.2),
                          checkmarkColor: Colors.green,
                          onSelected: (v) => setState(() => v
                              ? _dietaryRequirements.add(d)
                              : _dietaryRequirements.remove(d)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // MIX5: leftover / use-soon banner (expiry, low qty, stale stock)
              Builder(builder: (context) {
                final ranked = MixologistService.rankPantryForLeftovers(
                  pantryIngredients: pantryIngredients,
                  limit: 6,
                ).where((p) => p.score >= 40).toList();
                if (ranked.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 6),
                          Text(
                            'Use soon (leftovers first)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final p in ranked.take(4))
                        Text(
                          '· ${p.ingredient.name}'
                          '${p.reasons.isEmpty ? '' : ' — ${p.reasons.first}'}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.amber.shade900),
                        ),
                    ],
                  ),
                );
              }),

              // Generate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () => _generate(pantryIngredients),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.restaurant),
                  label: Text(
                      _isGenerating ? 'Thinking…' : 'Suggest a Dish'),
                ),
              ),

              // Suggestion card
              if (_suggestion != null) ...[
                const SizedBox(height: 20),
                _DishSuggestionCard(
                  suggestion: _suggestion!,
                  onSave: () => _saveAsRecipe(context, _suggestion!),
                  onTryAgain: () => _generate(pantryIngredients),
                ),
              ],
              if (_suggestion == null &&
                  !_isGenerating &&
                  inPantryCount == 0) ...[
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Mark some pantry items as "In Pantry" first.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DishSuggestionCard extends StatelessWidget {
  final DishSuggestion suggestion;
  final VoidCallback onSave;
  final VoidCallback onTryAgain;

  const _DishSuggestionCard({
    required this.suggestion,
    required this.onSave,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    suggestion.cuisine,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (suggestion.leftoverNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Clearing leftovers',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.amber.shade900,
                    ),
              ),
              const SizedBox(height: 4),
              ...suggestion.leftoverNotes.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '· $n',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ),
            ],
            const Divider(height: 16),
            Text('Ingredients',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            ...suggestion.ingredients.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record,
                          size: 8, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        i.quantity > 0
                            ? '${i.quantity} ${i.unit}  ${i.name}'
                            : i.name,
                        style: TextStyle(
                            color: i.optional
                                ? Colors.grey
                                : null,
                            fontSize: 13),
                      ),
                      if (i.optional) ...[
                        const SizedBox(width: 4),
                        const Text('opt.',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ],
                  ),
                )),
            const Divider(height: 16),
            Text('How to cook',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(suggestion.instructions,
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(suggestion.rationale,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTryAgain,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_alt, size: 16),
                    label: const Text('Save to Chef'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
