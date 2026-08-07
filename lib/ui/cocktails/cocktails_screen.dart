import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../components/title_tile.dart';
import '../components/tag_chip.dart';
import '../components/common_drawer.dart';
import '../components/import_export.dart';
import '../components/smart_image.dart';
import '../components/swipeable_list_item.dart';
import '../components/themed_state_tile.dart';
import '../components/ingredient_list_sort.dart';
import '../components/photo_source_picker.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/bar_ingredient_provider.dart';
import '../../providers/pantry_ingredient_provider.dart';
import '../../services/import_service.dart';
import '../../services/revenuecat_service.dart';
import '../../services/mixologist_service.dart';
import '../../services/barcode_service.dart';
import '../../services/recipe_share_service.dart';
import '../../models/models.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../core/units.dart';
import '../../services/tag_library_service.dart';
import '../components/tag_combobox.dart';
import '../components/native_ad_widget.dart';
import '../components/ad_slots.dart';

class CocktailsScreen extends ConsumerStatefulWidget {
  const CocktailsScreen({super.key});

  @override
  ConsumerState<CocktailsScreen> createState() => _CocktailsScreenState();
}

class _CocktailsScreenState extends ConsumerState<CocktailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortByAvailability = false;
  bool _favouritesOnly = false;

  /// My Bar list sort (drawer). Sticky order until sort mode changes.
  final IngredientListOrder _barOrder = IngredientListOrder();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
        ImportedRecipe(r, await repo.getIngredientsOnce(r.supabaseId)),
      );
    }
    return ImportService.exportRecipes(
      imported,
      unitSystem: ref.read(unitSystemProvider),
    );
  }

  Future<ImportPersistResult> _importRecipes(
    ImportBatch batch,
    String recipeType,
  ) async {
    final repo = ref.read(recipeRepositoryProvider);
    final existing = await repo.watchRecipes().first;
    var inserted = 0;
    var updated = 0;
    for (final ir in batch.recipes) {
      // Force the type to this screen so a generic recipe file lands here.
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

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final isPro = isProAsync.value ?? false;
    final cocktailRecipes =
        ref.watch(recipesProvider('cocktail')).value ?? const <Recipe>[];

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Cocktails',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                actionsBuilder: _tabController.index == 0
                    ? (color) => [
                        IconButton(
                          icon: Icon(Icons.import_export, color: color),
                          tooltip: 'Import / Export cocktails',
                          onPressed: () => showImportExportSheet(
                            context,
                            ModuleImportExport(
                              kind: ImportService.kindRecipe,
                              label: 'Cocktails',
                              fileBaseName: 'sisu_cocktails',
                              exportCurrent: () =>
                                  _exportRecipes(cocktailRecipes),
                              existingNames: () async =>
                                  cocktailRecipes.map((r) => r.name).toList(),
                              persist: (batch) =>
                                  _importRecipes(batch, 'cocktail'),
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
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(icon: Icon(Icons.local_bar), text: 'Cocktails'),
                  Tab(icon: Icon(Icons.liquor), text: 'My Bar'),
                  Tab(icon: Icon(Icons.auto_fix_high), text: 'Mixologist'),
                  Tab(icon: Icon(Icons.science), text: 'House'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CocktailsTab(
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      onSearchChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                      sortByAvailability: _sortByAvailability,
                      onSortByAvailabilityChanged: (v) =>
                          setState(() => _sortByAvailability = v),
                      favouritesOnly: _favouritesOnly,
                      onFavouritesChanged: (v) =>
                          setState(() => _favouritesOnly = v),
                      key: const ValueKey('cocktails_tab'),
                    ),
                    _BarTab(order: _barOrder),
                    const _MixologistTab(),
                    const _SyrupsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isProAsync.when(
        data: (isPro) {
          if (_tabController.index == 2) return null; // no FAB on Mixologist
          if (_tabController.index == 0) {
            return FloatingActionButton(
              heroTag: 'cocktail_fab',
              onPressed: () => isPro
                  ? _showAddRecipeDialog(context)
                  : _showProRequiredDialog(context),
              child: const Icon(Icons.add),
            );
          }
          if (_tabController.index == 3) {
            return FloatingActionButton(
              heroTag: 'syrup_fab',
              onPressed: () => isPro
                  ? _showAddSyrupDialog(context)
                  : _showProRequiredDialog(
                      context,
                      feature: 'custom house recipes',
                    ),
              tooltip: 'Add house recipe',
              child: const Icon(Icons.add),
            );
          }
          return FloatingActionButton(
            heroTag: 'bar_fab',
            onPressed: () => isPro
                ? _showAddBarIngredientDialog(context)
                : _showProRequiredDialog(
                    context,
                    feature: 'custom bar ingredients',
                  ),
            tooltip: 'Add custom ingredient',
            child: const Icon(Icons.add),
          );
        },
        loading: () => const FloatingActionButton(
          onPressed: null,
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => const FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.error),
        ),
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
                          leading: const Icon(
                            Icons.collections_bookmark_outlined,
                          ),
                          title: const Text('Collections'),
                          onTap: () => context.push(AppRoutes.collections),
                        ),
                        // #136: only shown on My Bar — it's the only tab that
                        // reads _barOrder, so it silently no-op'd elsewhere.
                        if (_tabController.index == 1) ...[
                          const Divider(),
                          SectionHeader(title: 'My Bar sort'),
                          for (final mode in IngredientListSort.values)
                            ListTile(
                              dense: true,
                              leading: Icon(
                                _barOrder.sort == mode
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                              ),
                              title: Text(
                                mode.label,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () {
                                setState(() => _barOrder.setSort(mode));
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

  void _showProRequiredDialog(
    BuildContext context, {
    String feature = 'custom cocktails',
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sisu Mate Pro Required'),
        content: Text(
          'Creating $feature is a Pro feature. Upgrade to unlock editing and unlimited entries.',
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
  }

  void _showAddRecipeDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    context.push(
      AppRoutes.recipeEditor,
      extra: AddEditRecipeArgs(
        recipeType: RecipeType.cocktail,
        onSave: (recipe, ingredients, removedIngredients) async {
          final repo = ref.read(recipeRepositoryProvider);
          await repo.addRecipe(recipe);
          for (final ingredient in ingredients) {
            await repo.addIngredient(ingredient);
          }
          if (mounted) {
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(content: Text('${recipe.name} added')),
            );
          }
        },
      ),
    );
  }

  void _showAddBarIngredientDialog(BuildContext context) {
    _showBarIngredientEditDialog(context, null);
  }

  void _showAddSyrupDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    context.push(
      AppRoutes.recipeEditor,
      extra: AddEditRecipeArgs(
        recipeType: RecipeType.syrup,
        onSave: (recipe, ingredients, removedIngredients) async {
          final repo = ref.read(recipeRepositoryProvider);
          await repo.addRecipe(recipe);
          for (final ingredient in ingredients) {
            await repo.addIngredient(ingredient);
          }
          if (mounted) {
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(content: Text('${recipe.name} added')),
            );
          }
        },
      ),
    );
  }
}

// ── Cocktails tab ─────────────────────────────────────────────────────────────

class _CocktailsTab extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool sortByAvailability;
  final ValueChanged<bool> onSortByAvailabilityChanged;
  final bool favouritesOnly;
  final ValueChanged<bool> onFavouritesChanged;

  const _CocktailsTab({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortByAvailability,
    required this.onSortByAvailabilityChanged,
    required this.favouritesOnly,
    required this.onFavouritesChanged,
  });

  @override
  ConsumerState<_CocktailsTab> createState() => _CocktailsTabState();
}

class _CocktailsTabState extends ConsumerState<_CocktailsTab> {
  /// Selected cuisine tags (AND — cocktail must include every selected tag).
  final Set<String> _cuisineFilters = {};

  /// Selected flavor tags (AND).
  final Set<String> _flavorFilters = {};

  /// Ad slots for the first grid (stable across rebuilds; see ad_slots.dart).
  final NativeAdSlotCache _adSlotCache = NativeAdSlotCache();

  /// Suggested + custom tags from [TagLibraryService] (for filter chips).
  List<String> _libraryCuisine = const [];
  List<String> _libraryFlavor = const [];

  /// Avoid re-running missing-count sync every rebuild.
  bool _didSyncMissing = false;

  static bool _hasAllTags(List<String> haystack, Set<String> needles) {
    if (needles.isEmpty) return true;
    final lower = haystack.map((t) => t.toLowerCase()).toSet();
    return needles.every((n) => lower.contains(n.toLowerCase()));
  }

  @override
  void initState() {
    super.initState();
    TagLibraryService.instance.options(TagKind.cuisine).then((v) {
      if (mounted) setState(() => _libraryCuisine = v);
    });
    TagLibraryService.instance.options(TagKind.flavor).then((v) {
      if (mounted) setState(() => _libraryFlavor = v);
    });
    // Seeded recipes default missingIngredientCount=0; recompute against My Bar.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didSyncMissing) return;
      _didSyncMissing = true;
      await ref.read(recipeRepositoryProvider).syncMissingIngredientCounts();
    });
  }

  Widget _buildHeader({
    required Recipe? dailyCocktail,
    required List<String> cuisineOptions,
    required List<String> flavorOptions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dailyCocktail != null)
          _FeaturedCocktailBanner(recipe: dailyCocktail),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: 'Search cocktails...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: widget.onSearchChanged,
          ),
        ),
        // Sort + Favourites on one row (scrolls sideways on very narrow screens).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Sort by availability'),
                avatar: const Icon(Icons.sort, size: 16),
                selected: widget.sortByAvailability,
                selectedColor: SisuColors.completedBackground.withValues(
                  alpha: 0.2,
                ),
                checkmarkColor: SisuColors.completedBackground,
                onSelected: widget.onSortByAvailabilityChanged,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Favourites'),
                avatar: const Icon(Icons.favorite, size: 16),
                selected: widget.favouritesOnly,
                selectedColor: Colors.red.withValues(alpha: 0.15),
                checkmarkColor: Colors.red,
                onSelected: widget.onFavouritesChanged,
              ),
              if (_cuisineFilters.isNotEmpty || _flavorFilters.isNotEmpty) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Clear tags'),
                  avatar: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() {
                    _cuisineFilters.clear();
                    _flavorFilters.clear();
                  }),
                ),
              ],
            ],
          ),
        ),
        if (cuisineOptions.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                for (final c in cuisineOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      selected: _cuisineFilters.contains(c),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _cuisineFilters.add(c);
                        } else {
                          _cuisineFilters.remove(c);
                        }
                      }),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        if (flavorOptions.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                for (final f in flavorOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      selected: _flavorFilters.contains(f),
                      selectedColor: Colors.orange.withValues(alpha: 0.25),
                      checkmarkColor: Colors.orange[700],
                      onSelected: (v) => setState(() {
                        if (v) {
                          _flavorFilters.add(f);
                        } else {
                          _flavorFilters.remove(f);
                        }
                      }),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider('cocktail'));
    final dailyCocktail = ref.watch(dailyCocktailProvider);

    return recipesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading cocktails: $e')),
      data: (recipes) {
        final cuisineOptions = <String>{
          ..._libraryCuisine,
          for (final r in recipes) ...r.cuisine,
        }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        final flavorOptions = <String>{
          ..._libraryFlavor,
          for (final r in recipes) ...r.flavorProfiles,
        }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        final filtered = recipes.where((r) {
          final matchesSearch =
              widget.searchQuery.isEmpty ||
              r.name.toLowerCase().contains(widget.searchQuery) ||
              (r.description?.toLowerCase().contains(widget.searchQuery) ??
                  false) ||
              r.cuisine.any(
                (t) => t.toLowerCase().contains(widget.searchQuery),
              ) ||
              r.flavorProfiles.any(
                (t) => t.toLowerCase().contains(widget.searchQuery),
              );
          final matchesFav = !widget.favouritesOnly || r.isFavourite;
          final matchesCuisine = _hasAllTags(r.cuisine, _cuisineFilters);
          final matchesFlavor = _hasAllTags(r.flavorProfiles, _flavorFilters);
          return matchesSearch && matchesFav && matchesCuisine && matchesFlavor;
        }).toList();

        final header = _buildHeader(
          dailyCocktail: dailyCocktail,
          cuisineOptions: cuisineOptions,
          flavorOptions: flavorOptions,
        );

        // Empty filtered list still scrolls so filters remain reachable.
        final headerSliver = SliverToBoxAdapter(child: header);

        if (filtered.isEmpty) {
          return CustomScrollView(
            slivers: [
              headerSliver,
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No cocktails match your filters.'),
                  ),
                ),
              ),
            ],
          );
        }

        // #311 — never reserve grid ad cells on Pro (shrink leaves holes).
        final showAds = !(ref.watch(isProProvider).value ?? false);

        if (!widget.sortByAvailability) {
          return CustomScrollView(
            slivers: [
              headerSliver,
              _cocktailGridSliver(filtered, withAds: showAds),
            ],
          );
        }

        final total = filtered.length;
        final canMake = filtered
            .where((r) => r.missingIngredientCount == 0)
            .toList();
        final almost = filtered
            .where((r) => r.missingIngredientCount == 1)
            .toList();
        final needMore = filtered
            .where((r) => r.missingIngredientCount > 1)
            .toList();

        // Always show the three buckets with count/total so an empty bar
        // reads "Can make now · 0/162", not "Can make now · 162".
        // Native tile ads go in the FIRST non-empty bucket (start of list).
        return CustomScrollView(
          slivers: [
            headerSliver,
            _sectionHeaderSliver('Can make now · ${canMake.length}/$total'),
            if (canMake.isNotEmpty)
              _cocktailGridSliver(canMake, withAds: showAds),
            _sectionHeaderSliver('Almost there · ${almost.length}/$total'),
            if (almost.isNotEmpty)
              _cocktailGridSliver(
                  almost, withAds: showAds && canMake.isEmpty),
            _sectionHeaderSliver(
              'Need ingredients · ${needMore.length}/$total',
            ),
            if (needMore.isNotEmpty)
              _cocktailGridSliver(
                needMore,
                withAds: showAds && canMake.isEmpty && almost.isEmpty,
              ),
          ],
        );
      },
    );
  }

  static Widget _sectionHeaderSliver(String label) {
    return _SectionDivider(label: label);
  }

  /// Two-column recipe grid; when [withAds] splices native tile ads into
  /// ≤4 random slots near the start (user policy; see ad_slots.dart).
  Widget _cocktailGridSliver(List<Recipe> recipes, {bool withAds = false}) {
    final slots = withAds ? _adSlotCache(recipes.length) : const <int>[];
    final count = recipes.length + slots.length;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.55,
        ),
        delegate: SliverChildBuilderDelegate((_, i) {
          if (isNativeAdSlot(i, slots)) {
            return const NativeAdWidget(
              style: NativeAdTileStyle.cocktailTile,
              contextHint: 'cocktails',
            );
          }
          return _CocktailCard(recipe: recipes[nativeAdContentIndex(i, slots)]);
        }, childCount: count),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Divider()),
          ],
        ),
      ),
    );
  }
}

/// Two-column cocktail card (matches Chef grid layout).
class _CocktailCard extends ConsumerWidget {
  final Recipe recipe;
  const _CocktailCard({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavorColor = Colors.orange[700]!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push(AppRoutes.cocktailRecipe, extra: recipe),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: SmartImage(
                      assetName: recipe.imageAsset,
                      userPhotoPath: recipe.localPath,
                      width: double.infinity,
                      height: 90,
                      fit: BoxFit.cover,
                      customFallback: Container(
                        color: Colors.deepPurple.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.local_bar,
                          size: 36,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
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
                    if (recipe.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        recipe.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (recipe.cuisine.isNotEmpty ||
                        recipe.flavorProfiles.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (final t in recipe.cuisine.take(2))
                            TagChip(
                              label: t,
                              color: SisuColors.completedBackground,
                            ),
                          for (final t in recipe.flavorProfiles.take(2))
                            TagChip(label: t, color: flavorColor),
                        ],
                      ),
                    ],
                    if (recipe.missingIngredientCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Missing ${recipe.missingIngredientCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          // Same red as not-in-stock tiles (theme.md §6.5).
                          color: SisuColors.itemStateColors(
                            Theme.of(context).brightness == Brightness.dark,
                            ItemListState.unavailable,
                          ).desc,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Can make',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SisuColors.completedBackground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCocktailBanner extends StatelessWidget {
  final Recipe recipe;
  const _FeaturedCocktailBanner({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: Colors.deepPurple.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.push(AppRoutes.cocktailRecipe, extra: recipe),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: SmartImage(
                      assetName: recipe.imageAsset,
                      userPhotoPath: recipe.localPath,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      customFallback: const Icon(
                        Icons.today,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s cocktail',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        recipe.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (recipe.glassware != null)
                        Text(
                          recipe.glassware!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.deepPurple),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Cocktail detail ───────────────────────────────────────────────────────────

// #131: shared by the live "N missing" count and "Add missing to shopping" so
// they can never disagree — non-garnish, non-optional ingredients not in bar.
List<RecipeIngredient> _missingRecipeIngredients(
  List<RecipeIngredient> ingredients,
  List<BarIngredient> barIngredients,
) {
  final barNames = barIngredients
      .where((b) => b.inMyBar)
      .map((b) => b.name.toLowerCase().trim())
      .toSet();
  return ingredients
      .where(
        (i) =>
            !i.isGarnish &&
            !i.isOptional &&
            !barNames.contains(i.name.toLowerCase().trim()),
      )
      .toList();
}

class CocktailRecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const CocktailRecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<CocktailRecipeDetailScreen> createState() =>
      CocktailRecipeDetailScreenState();
}

class CocktailRecipeDetailScreenState
    extends ConsumerState<CocktailRecipeDetailScreen> {
  int _servings = 1;

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(
      recipeIngredientsProvider(widget.recipe.supabaseId),
    );
    final barAsync = ref.watch(barIngredientsProvider);
    final isProAsync = ref.watch(isProProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (tileContext) => TitleTile(
                title: widget.recipe.name,
                onMenuPressed: () => Scaffold.of(tileContext).openEndDrawer(),
                actionsBuilder: (iconColor) => [
                  IconButton(
                    icon: Icon(
                      widget.recipe.isFavourite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.recipe.isFavourite ? Colors.red : iconColor,
                    ),
                    tooltip: 'Favourite',
                    onPressed: () async {
                      widget.recipe.isFavourite = !widget.recipe.isFavourite;
                      await ref
                          .read(recipeRepositoryProvider)
                          .updateRecipe(widget.recipe);
                      if (mounted) setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.ios_share, color: iconColor),
                    tooltip: 'Print / Share',
                    onPressed: () => ingredientsAsync.whenData(
                      (ingredients) => RecipeShareService.shareRecipeCard(
                        recipe: widget.recipe,
                        ingredients: ingredients,
                      ),
                    ),
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
                    // Offline cocktail art — sized for detail hero (~full width × 200).
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: SmartImage(
                          assetName: widget.recipe.imageAsset,
                          userPhotoPath: widget.recipe.localPath,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          customFallback: Container(
                            color: Colors.deepPurple.withValues(alpha: 0.12),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.local_bar,
                              size: 56,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.recipe.description != null) ...[
                      Text(
                        widget.recipe.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.recipe.glassware != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.wine_bar,
                            size: 16,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.recipe.glassware!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.recipe.cuisine.isNotEmpty ||
                        widget.recipe.flavorProfiles.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final t in widget.recipe.cuisine)
                            Chip(
                              label: Text(
                                t,
                                style: const TextStyle(fontSize: 12),
                              ),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: SisuColors.completedBackground
                                  .withValues(alpha: 0.15),
                            ),
                          for (final t in widget.recipe.flavorProfiles)
                            Chip(
                              label: Text(
                                t,
                                style: const TextStyle(fontSize: 12),
                              ),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.orange.withValues(
                                alpha: 0.18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Technique',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final t in ['Shake', 'Stir', 'Build'])
                          ActionChip(
                            label: Text(t),
                            onPressed: () => _showTechniqueSheet(context, t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    // Wrap of chips — 7 options must not use SegmentedButton
                    // (that overflows on narrow phones).
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Servings:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
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
                                  horizontal: 8,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ingredientsAsync.when(
                      data: (ingredients) => Column(
                        children: ingredients
                            .map(
                              (i) => _IngredientAvailabilityTile(
                                ingredient: i,
                                servingsMultiplier: _servings,
                              ),
                            )
                            .toList(),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    if (ingredientsAsync.asData != null &&
                        barAsync.asData != null)
                      Builder(
                        builder: (_) {
                          final missing = _missingRecipeIngredients(
                            ingredientsAsync.asData!.value,
                            barAsync.asData!.value,
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
                                  barAsync.asData!.value,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    if (widget.recipe.recipeType == 'cocktail')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.groups, size: 16),
                            label: const Text('Build a Round'),
                            onPressed: () => context.push(
                              AppRoutes.cocktailBatch,
                              extra: widget.recipe,
                            ),
                          ),
                        ),
                      ),
                    if (widget.recipe.instructions != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Instructions',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        UnitConverter.convertTemperaturesInText(
                          widget.recipe.instructions!,
                          ref.watch(unitSystemProvider),
                        ),
                      ),
                    ],
                    if (widget.recipe.story != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Barman\'s Tale',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.format_quote,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.recipe.story!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (widget.recipe.recipeType == 'syrup') ...[
                      const SizedBox(height: 20),
                      Text(
                        'Used in cocktails',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, _) {
                          final cocktailsAsync = ref.watch(
                            cocktailRecipesForIngredientProvider(
                              widget.recipe.name,
                            ),
                          );
                          return cocktailsAsync.when(
                            data: (list) {
                              if (list.isEmpty) {
                                return Text(
                                  'Not used in any cocktail',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey),
                                );
                              }
                              return Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final cocktail in list)
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      label: Text(
                                        cocktail.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () => context.push(
                                        AppRoutes.cocktailRecipe,
                                        extra: cocktail,
                                      ),
                                    ),
                                ],
                              );
                            },
                            loading: () => const Text('Loading…'),
                            error: (_, _) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                    // ── Tasting Log ───────────────────────────────────────
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'My Tasting Log',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (widget.recipe.tastingLog.isNotEmpty)
                          _StarRow(
                            rating:
                                (widget.recipe.tastingLog
                                            .map((r) => r.rating)
                                            .reduce((a, b) => a + b) /
                                        widget.recipe.tastingLog.length)
                                    .round(),
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.recipe.tastingLog.isEmpty)
                      Text(
                        'No tasting notes yet. Add one after your next pour.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ...widget.recipe.tastingLog.reversed.map((record) {
                      final date = record.tastedAt;
                      final dateStr = date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _StarRow(rating: record.rating, size: 14),
                                  const Spacer(),
                                  if (dateStr.isNotEmpty)
                                    Text(
                                      dateStr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                ],
                              ),
                              if (record.location != null &&
                                  record.location!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  record.location!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                              if (record.notes != null &&
                                  record.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  record.notes!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.star_outline, size: 16),
                        label: const Text('Add tasting note'),
                        onPressed: () => _showAddTastingDialog(context),
                      ),
                    ),
                    if (!widget.recipe.isBundled) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          label: const Text(
                            'Delete recipe',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () => _confirmDelete(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
                                  content: Text(
                                    'Editing requires Sisu Mate Pro',
                                  ),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          widget.recipe.isFavourite
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        title: Text(
                          widget.recipe.isFavourite
                              ? 'Remove favourite'
                              : 'Add favourite',
                        ),
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
                          ingredientsAsync.whenData(
                            (ingredients) => RecipeShareService.shareRecipeCard(
                              recipe: widget.recipe,
                              ingredients: ingredients,
                            ),
                          );
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
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                      if (!widget.recipe.isBundled)
                        ListTile(
                          leading: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'Delete recipe',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDelete(context);
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

  Future<void> _showAddTastingDialog(BuildContext context) async {
    final record = await showDialog<TastingRecord>(
      context: context,
      builder: (_) => const _AddTastingDialog(),
    );
    if (record == null) return;
    widget.recipe.tastingLog = [...widget.recipe.tastingLog, record];
    await ref.read(recipeRepositoryProvider).updateRecipe(widget.recipe);
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('Delete "${widget.recipe.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(recipeRepositoryProvider).deleteRecipe(widget.recipe);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _addMissingToShopping(
    BuildContext context,
    List<RecipeIngredient> ingredients,
    List<BarIngredient> barIngredients,
  ) async {
    final missing = _missingRecipeIngredients(ingredients, barIngredients);
    if (missing.isEmpty) return;
    final repo = ref.read(shoppingRepositoryProvider);
    var addedCount = 0;
    for (final ingredient in missing) {
      final added = await repo.ensureInShopping(
        name: ingredient.name,
        origin: 'bar',
      );
      if (added) addedCount++;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            addedCount == 0
                ? 'All missing ingredients already on the shopping list'
                : '$addedCount ingredient${addedCount == 1 ? '' : 's'} added to shopping',
          ),
        ),
      );
    }
  }

  void _showEditDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repo = ref.read(recipeRepositoryProvider);
    final existingIngredients = await repo.getIngredientsOnce(
      widget.recipe.supabaseId,
    );
    if (!context.mounted) return;
    context.push(
      AppRoutes.recipeEditor,
      extra: AddEditRecipeArgs(
        recipeType: switch (widget.recipe.recipeType) {
          'menu' => RecipeType.menu,
          'syrup' => RecipeType.syrup,
          _ => RecipeType.cocktail,
        },
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
              SnackBar(content: Text('${recipe.name} updated')),
            );
          }
        },
      ),
    );
  }
}

// Cocktail recipe detail ingredient row.
// Colour tells stock/shopping state (theme.md §6.5) — no status labels.
// Secondary line: quantity; tertiary: flavor profiles (+ garnish/optional notes).
class _IngredientAvailabilityTile extends ConsumerWidget {
  final RecipeIngredient ingredient;
  final int servingsMultiplier;
  const _IngredientAvailabilityTile({
    required this.ingredient,
    this.servingsMultiplier = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barAsync = ref.watch(barIngredientsProvider);
    final shoppingNames =
        ref.watch(shoppingItemNamesProvider).asData?.value ?? {};
    return barAsync.when(
      data: (barIngredients) {
        final nameLower = ingredient.name.toLowerCase().trim();
        // #186: every ingredient is physically in the bar or not — no
        // separate "seeded catalog row" tier. A recipe ingredient that's
        // never been added yet is simply not in the bar, same as one that
        // is in the catalog but unstocked.
        final inBar = barIngredients.any(
          (b) => b.name.toLowerCase().trim() == nameLower && b.inMyBar,
        );

        // MIX2: catalog substitute1/2 OR static substitute graph.
        final viaIngredient = (!inBar && !ingredient.isGarnish)
            ? barIngredients.where((b) {
                if (!b.inMyBar) return false;
                return b.substitute1?.toLowerCase().trim() == nameLower ||
                    b.substitute2?.toLowerCase().trim() == nameLower;
              }).firstOrNull
            : null;
        final graphSub =
            (!inBar && !ingredient.isGarnish && viaIngredient == null)
            ? MixologistService.bestCountingSubstitute(
                neededName: ingredient.name,
                barIngredients: barIngredients,
              )
            : null;
        final inBarViaSub = viaIngredient != null || graphSub != null;
        final inShopping = shoppingNames.contains(nameLower);

        final barIngredient = barIngredients
            .where((b) => b.name.toLowerCase().trim() == nameLower)
            .firstOrNull;

        // Colour tells state — no bag/tick status icons, no stock prose.
        final ItemListState state;
        final IconData leadingIcon;
        if (ingredient.isGarnish) {
          state = ItemListState.hidden;
          leadingIcon = Icons.local_florist_outlined;
        } else if (inBar || inBarViaSub) {
          state = ItemListState.stocked;
          leadingIcon = inBarViaSub ? Icons.swap_horiz : Icons.liquor;
        } else if (inShopping) {
          state = ItemListState.shopping;
          leadingIcon = Icons.liquor;
        } else {
          // #186: not in bar reads the same (red/unavailable) whether or
          // not this exact name has ever been added to the bar catalog —
          // there's no separate "unknown ingredient" tier to hint at.
          state = ItemListState.unavailable;
          leadingIcon = Icons.liquor;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final c = SisuColors.itemStateColors(isDark, state);

        final unitSystem = ref.watch(unitSystemProvider);
        final qtyDisplay = () {
          final s = UnitConverter.format(
            ingredient.quantity,
            ingredient.unit,
            unitSystem,
            scale: servingsMultiplier.toDouble(),
            preferBarUnits: true,
          );
          return s.isEmpty ? null : s;
        }();

        // Flavor profiles from the matching bar catalog row (or via-sub).
        final profiles =
            (barIngredient?.flavorProfiles.isNotEmpty == true
                ? barIngredient!.flavorProfiles
                : viaIngredient?.flavorProfiles) ??
            const <String>[];
        final flavorLine = profiles.isEmpty
            ? null
            : profiles.take(4).join(' · ');

        final extra = <String>[
          ?flavorLine,
          if (ingredient.isOptional) 'Optional',
          if (ingredient.isGarnish && ingredient.garnishNotes != null)
            ingredient.garnishNotes!,
          if (viaIngredient != null) 'Sub: ${viaIngredient.name}',
          if (graphSub != null)
            'Sub: ${graphSub.using} (${(graphSub.confidence * 100).round()}% — ${graphSub.note})',
          if (!inBar && !inBarViaSub && ingredient.substitute != null)
            'Try: ${ingredient.substitute}',
        ];

        void openInBar() {
          final list = barIngredients;
          var idx = list.indexWhere(
            (b) => b.name.toLowerCase().trim() == nameLower,
          );
          if (idx < 0 && viaIngredient != null) {
            idx = list.indexWhere(
              (b) => b.supabaseId == viaIngredient.supabaseId,
            );
          }
          if (idx < 0 && graphSub != null) {
            idx = list.indexWhere(
              (b) =>
                  b.name.toLowerCase().trim() ==
                  graphSub.using.toLowerCase().trim(),
            );
          }
          if (idx < 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${ingredient.name} is not in My Bar — swipe In Bar to add it',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
          context.push(
            AppRoutes.barIngredientDetail,
            extra: (items: list, initialIndex: idx),
          );
        }

        final tile = ThemedStateTile(
          state: state,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          leading: Icon(leadingIcon, color: c.desc),
          title: ingredient.name,
          subtitle: qtyDisplay,
          tertiary: extra.isEmpty ? null : extra.join(' · '),
          onTap: ingredient.isGarnish ? null : openInBar,
        );

        if (ingredient.isGarnish) return tile;

        return Slidable(
          key: ValueKey(ingredient.supabaseId),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (ctx) => _addSingleToShopping(ctx, ref),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.add_shopping_cart,
                label: 'Shopping',
              ),
            ],
          ),
          // #186: one physical toggle — in the bar or not — regardless of
          // whether this ingredient already has a catalog row. If it
          // doesn't, the first tap creates it (transparently) already
          // marked in-bar; that's still just "In Bar", not a separate
          // "Track" action.
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) async {
                  if (barIngredient != null) {
                    await ref
                        .read(barIngredientRepositoryProvider)
                        .toggleInMyBar(barIngredient);
                  } else {
                    final newIng = BarIngredient()
                      ..supabaseId =
                          'custom_bar_${nameLower.replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}'
                      ..name = ingredient.name
                      ..inMyBar = true
                      ..isBundled = false;
                    await ref
                        .read(barIngredientRepositoryProvider)
                        .addBarIngredient(newIng);
                  }
                },
                backgroundColor: SisuColors.completedBackground,
                foregroundColor: Colors.white,
                icon: inBar ? Icons.remove_circle_outline : Icons.check,
                label: inBar ? 'Remove' : 'In Bar',
              ),
            ],
          ),
          child: tile,
        );
      },
      loading: () => ListTile(
        title: Text(ingredient.name),
        subtitle: const Text('Checking bar...'),
      ),
      error: (e, _) =>
          ListTile(title: Text(ingredient.name), subtitle: Text('Error: $e')),
    );
  }

  Future<void> _addSingleToShopping(BuildContext context, WidgetRef ref) async {
    final added = await ref
        .read(shoppingRepositoryProvider)
        .ensureInShopping(name: ingredient.name, origin: 'bar');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '${ingredient.name} added to shopping'
                : '${ingredient.name} is already on the shopping list',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

// ── My Bar tab ────────────────────────────────────────────────────────────────

class _BarTab extends ConsumerStatefulWidget {
  final IngredientListOrder order;
  const _BarTab({required this.order});

  @override
  ConsumerState<_BarTab> createState() => _BarTabState();
}

class _BarTabState extends ConsumerState<_BarTab> {
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
    final barAsync = ref.watch(barIngredientsProvider);
    final shoppingNames =
        ref.watch(shoppingItemNamesProvider).asData?.value ?? {};
    // Rebuild when parent changes sort mode.
    if (_lastSortEpoch != widget.order.sortEpoch) {
      _lastSortEpoch = widget.order.sortEpoch;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ingredients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
        // MIX4: low-stock / stale purchase heads-up
        barAsync.when(
          data: (ingredients) {
            final low = MixologistService.lowStockBarItems(
              barIngredients: ingredients,
            );
            if (low.isEmpty) return const SizedBox.shrink();
            final top = low.take(3).toList();
            return Material(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bar may be low',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final item in top)
                      Text(
                        '${item.ingredient.name}: ${item.reason}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (low.length > 3)
                      Text(
                        '+${low.length - 3} more',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Expanded(
          child: barAsync.when(
            data: (ingredients) {
              // Order full list (sticky); search only filters the view.
              final ordered = widget.order.apply(
                items: ingredients,
                idOf: (i) => i.supabaseId,
                nameOf: (i) => i.name,
                categoryOf: (i) => i.category,
                inStockOf: (i) => i.inMyBar,
                inShoppingOf: (i) =>
                    shoppingNames.contains(i.name.toLowerCase().trim()),
              );
              final filtered = _searchQuery.isEmpty
                  ? ordered
                  : ordered
                        .where(
                          (i) => i.name.toLowerCase().contains(_searchQuery),
                        )
                        .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('No ingredients found.'));
              }
              // #311 — no ad indices when Pro.
              final isPro = ref.watch(isProProvider).value ?? false;
              final adSlots =
                  _adSlotCache.forList(filtered.length, showAds: !isPro);
              return ListView.builder(
                // Keys keep tiles stable when data updates without reordering.
                itemCount: filtered.length + adSlots.length,
                itemBuilder: (_, idx) {
                  if (isNativeAdSlot(idx, adSlots)) {
                    return const NativeAdWidget(contextHint: 'my-bar');
                  }
                  final ingredient =
                      filtered[nativeAdContentIndex(idx, adSlots)];
                  return _BarIngredientTile(
                    key: ValueKey(ingredient.supabaseId),
                    ingredient: ingredient,
                    allIngredients: filtered,
                  );
                },
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

class _BarIngredientTile extends ConsumerWidget {
  final BarIngredient ingredient;
  final List<BarIngredient> allIngredients;
  const _BarIngredientTile({
    super.key,
    required this.ingredient,
    required this.allIngredients,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cocktailsAsync = ref.watch(
      cocktailRecipesForIngredientProvider(ingredient.name),
    );
    // Drift stream of pending shopping names — drives blue "in cart" tile state.
    final shoppingNames =
        ref.watch(shoppingItemNamesProvider).asData?.value ?? {};

    final inBar = ingredient.inMyBar;
    final inShopping = shoppingNames.contains(
      ingredient.name.toLowerCase().trim(),
    );
    // Colour tells state (theme.md §6.5): green stocked > blue shopping > grey.
    final state = inBar
        ? ItemListState.stocked
        : inShopping
        ? ItemListState.shopping
        : ItemListState.defaults;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = SisuColors.itemStateColors(isDark, state);

    final cocktails = cocktailsAsync.asData?.value ?? const <Recipe>[];
    final cocktailSubtitle = cocktailsAsync.when(
      data: (list) => list.isEmpty
          ? 'Not used in any cocktail'
          : 'Used in ${list.length} cocktail${list.length == 1 ? '' : 's'}',
      loading: () => 'Loading…',
      error: (e, _) => '',
    );
    // #187: flavor profile gets its own colored chip (matching recipe
    // tiles) below — price stays plain text, unchanged.
    final priceLabel = ingredient.lastKnownPrice != null
        ? '\$${ingredient.lastKnownPrice!.toStringAsFixed(0)}'
        : null;
    final tertiary = [
      ?priceLabel,
      if (inShopping && !inBar) 'On shopping list',
    ].join(' · ');

    return SwipeableListItem.ingredientItem(
      isActive: inBar,
      isCustom: !ingredient.isBundled,
      isInShopping: inShopping,
      onToggleStatus: () =>
          ref.read(barIngredientRepositoryProvider).toggleInMyBar(ingredient),
      onAddToShopping: () => _addToShopping(context, ref),
      onMarkShoppingDone: () => _markShoppingDone(context, ref),
      onDelete: ingredient.isBundled
          ? null
          : () => _confirmDelete(context, ref),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        color: c.bg,
        elevation: 3,
        child: InkWell(
          onTap: () {
            final idx = allIngredients.indexWhere(
              (b) => b.supabaseId == ingredient.supabaseId,
            );
            context.push(
              AppRoutes.barIngredientDetail,
              extra: (items: allIngredients, initialIndex: idx < 0 ? 0 : idx),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IngredientLeading(ingredient: ingredient, color: c.desc),
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
                  cocktailSubtitle,
                  style: TextStyle(color: c.desc, fontSize: 13),
                ),
                if (cocktails.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final recipe in cocktails.take(8))
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: Text(
                            recipe.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => context.push(
                            AppRoutes.cocktailRecipe,
                            extra: recipe,
                          ),
                        ),
                    ],
                  ),
                ],
                if (ingredient.flavorProfiles.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      for (final f in ingredient.flavorProfiles)
                        TagChip(label: f, color: Colors.orange[700]!),
                    ],
                  ),
                ],
                if (tertiary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(tertiary, style: TextStyle(color: c.desc, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToShopping(BuildContext context, WidgetRef ref) async {
    final added = await ref
        .read(shoppingRepositoryProvider)
        .ensureInShopping(name: ingredient.name, origin: 'bar');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '${ingredient.name} added to shopping list'
                : '${ingredient.name} is already on the shopping list',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _markShoppingDone(BuildContext context, WidgetRef ref) async {
    final n = await ref
        .read(shoppingRepositoryProvider)
        .markPendingBoughtByName(ingredient.name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n > 0
                ? '${ingredient.name} marked bought'
                : 'No pending shopping line for ${ingredient.name}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete ingredient?'),
        content: Text('Remove "${ingredient.name}" from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
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
          .read(barIngredientRepositoryProvider)
          .deleteBarIngredient(ingredient);
    }
  }
}

// Leading image/icon tinted with the tile's state colour (no bag/status icons).
class _IngredientLeading extends StatelessWidget {
  final BarIngredient ingredient;
  final Color color;
  const _IngredientLeading({required this.ingredient, required this.color});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.liquor, color: color);

    if (ingredient.localPhotoPath != null &&
        ingredient.localPhotoPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.file(
          File(ingredient.localPhotoPath!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    if (ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          ingredient.imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    return fallback;
  }
}

// ── Bar ingredient edit dialog ────────────────────────────────────────────────

void _showBarIngredientEditDialog(
  BuildContext context,
  BarIngredient? existing,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => _BarIngredientEditDialog(existing: existing),
  );
}

class _BarIngredientEditDialog extends ConsumerStatefulWidget {
  final BarIngredient? existing;
  const _BarIngredientEditDialog({this.existing});

  @override
  ConsumerState<_BarIngredientEditDialog> createState() =>
      _BarIngredientEditDialogState();
}

class _BarIngredientEditDialogState
    extends ConsumerState<_BarIngredientEditDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String? _localPhotoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      if (e.lastKnownPrice != null) {
        _priceCtrl.text = e.lastKnownPrice!.toStringAsFixed(2);
      }
      _placeCtrl.text = e.lastPurchasePlace ?? '';
      _imageCtrl.text = e.imageUrl ?? '';
      _localPhotoPath = e.localPhotoPath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _placeCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await pickPhotoFromCameraOrGallery(context, imageQuality: 80);
    if (file != null && mounted) setState(() => _localPhotoPath = file.path);
  }

  Future<void> _scanBarcode() async {
    final result = await context.push<String>(AppRoutes.barcodeScanner);
    if (result == null || !mounted) return;
    final match = BarcodeService.lookup(result);
    if (match != null) {
      setState(() {
        if (_nameCtrl.text.isEmpty) {
          _nameCtrl.text = match.suggestedIngredientName;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recognised: ${match.bottleName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unknown barcode: $result — enter name manually'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _localPhotoPath != null && _localPhotoPath!.isNotEmpty;
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Ingredient' : 'Edit Ingredient',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo preview + picker
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasPhoto
                        ? Image.file(
                            File(_localPhotoPath!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _photoPlaceholder(),
                          )
                        : _photoPlaceholder(),
                  ),
                  _PhotoActionButton(
                    icon: Icons.add_a_photo,
                    onTap: _pickPhoto,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient name',
                    ),
                    autofocus: widget.existing == null,
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
            const SizedBox(height: 12),
            const Text(
              'Price & Purchase',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Price (USD)',
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _placeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Where bought',
                    ),
                  ),
                ),
              ],
            ),
            if (widget.existing != null &&
                widget.existing!.purchaseHistory.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    _showPurchaseHistory(context, widget.existing!),
                icon: const Icon(Icons.history, size: 16),
                label: Text(
                  'View ${widget.existing!.purchaseHistory.length} purchase records',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _imageCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _photoPlaceholder() => Container(
    width: 100,
    height: 100,
    color: Colors.grey[200],
    child: const Icon(Icons.liquor, size: 40, color: Colors.grey),
  );

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);

    final repo = ref.read(barIngredientRepositoryProvider);
    final navigator = Navigator.of(context);
    final price = double.tryParse(_priceCtrl.text.trim());
    final place = _placeCtrl.text.trim();
    final imageUrl = _imageCtrl.text.trim().isEmpty
        ? null
        : _imageCtrl.text.trim();

    try {
      if (widget.existing == null) {
        final ingredient = BarIngredient()
          ..supabaseId =
              'bar_custom_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}'
          ..name = name
          ..lastKnownPrice = price
          ..lastPurchasePlace = place.isEmpty ? null : place
          ..imageUrl = imageUrl
          ..localPhotoPath = _localPhotoPath
          ..isBundled = false;
        if (price != null && place.isNotEmpty) {
          await repo.addBarIngredient(ingredient);
          await repo.recordPurchase(ingredient, price: price, place: place);
        } else {
          await repo.addBarIngredient(ingredient);
        }
      } else {
        final e = widget.existing!
          ..name = name
          ..imageUrl = imageUrl
          ..localPhotoPath = _localPhotoPath;
        if (price != null && place.isNotEmpty) {
          await repo.recordPurchase(e, price: price, place: place);
        } else {
          e.lastPurchasePlace = place.isEmpty ? e.lastPurchasePlace : place;
          await repo.updateBarIngredient(e);
        }
      }
      if (mounted) navigator.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PhotoActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: SisuColors.completedBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// ── Barcode scanner screen (BC8) ──────────────────────────────────────────────

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => BarcodeScannerScreenState();
}

class BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Bottle Barcode')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              final value = barcode?.rawValue;
              if (value == null) return;
              _scanned = true;
              Navigator.of(context).pop(value);
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point camera at the barcode on the bottle',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showPurchaseHistory(BuildContext context, BarIngredient ingredient) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('${ingredient.name} — Purchase History'),
      content: SizedBox(
        width: 320,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: ingredient.purchaseHistory.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (_, i) {
            final record =
                ingredient.purchaseHistory[ingredient.purchaseHistory.length -
                    1 -
                    i]; // newest first
            final date = record.purchaseDate;
            final dateStr = date != null
                ? '${date.day}/${date.month}/${date.year}'
                : 'Unknown date';
            return ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long, size: 20),
              title: Text(
                '\$${record.price?.toStringAsFixed(2) ?? '?'} ${record.currency}',
              ),
              subtitle: Text('${record.place ?? 'Unknown'} · $dateStr'),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

// ── Mixologist tab ────────────────────────────────────────────────────────────

const _cocktailVibes = [
  'tropical',
  'tiki',
  'fresh',
  'citrus',
  'sour',
  'smoky',
  'bitter',
  'spirit-forward',
  'floral',
  'herbal',
  'spiced',
  'fizzy',
];

class _MixologistTab extends ConsumerStatefulWidget {
  const _MixologistTab();

  @override
  ConsumerState<_MixologistTab> createState() => _MixologistTabState();
}

class _MixologistTabState extends ConsumerState<_MixologistTab> {
  final Set<String> _selectedVibes = {};
  String? _selectedOccasion;
  CocktailStrength _strength = CocktailStrength.session;
  String _glassware = 'Auto';
  int _servings = 1;
  CocktailSuggestion? _suggestion;
  bool _isGenerating = false;
  List<MakeableRecipeScore>? _makeable;
  bool _loadingMakeable = false;

  Future<void> _loadMakeable(
    List<BarIngredient> bar,
    List<PantryIngredient> pantry,
  ) async {
    setState(() => _loadingMakeable = true);
    final cocktails =
        ref.read(recipesProvider('cocktail')).asData?.value ?? const [];
    final repo = ref.read(recipeRepositoryProvider);
    final map = <String, List<RecipeIngredient>>{};
    for (final r in cocktails) {
      map[r.supabaseId] = await repo.getIngredientsOnce(r.supabaseId);
    }
    if (!mounted) return;
    final ranked = MixologistService.rankMakeableTonight(
      recipes: cocktails,
      ingredientsByRecipeId: map,
      barIngredients: bar,
      pantryIngredients: pantry,
    );
    setState(() {
      _makeable = ranked;
      _loadingMakeable = false;
    });
  }

  void _generate(List<BarIngredient> allIngredients) {
    final vibes = _selectedVibes.isEmpty ? ['fresh'] : _selectedVibes.toList();
    if (_selectedOccasion != null) {
      for (final v
          in MixologistService.occasionVibes[_selectedOccasion] ?? []) {
        if (!vibes.contains(v)) vibes.add(v);
      }
    }
    setState(() {
      _isGenerating = true;
      _suggestion = null;
    });
    final result = MixologistService.suggest(
      vibes: vibes,
      barIngredients: allIngredients,
      strength: _strength,
      glassware: _glassware,
      servings: _servings,
    );
    setState(() {
      _suggestion = result;
      _isGenerating = false;
    });
  }

  void _saveAsRecipe(BuildContext context) {
    final s = _suggestion;
    if (s == null) return;
    final unitSystem = ref.read(unitSystemProvider);
    final ingredientList = s.ingredients
        .map((i) {
          final qty = i.quantity > 0
              ? '${UnitConverter.format(i.quantity, i.unit, unitSystem, preferBarUnits: true)} '
              : '';
          return '$qty${i.name}${i.optional ? " (optional)" : ""}';
        })
        .join('\n');
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    context.push(
      AppRoutes.recipeEditor,
      extra: AddEditRecipeArgs(
        recipeType: RecipeType.cocktail,
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
              SnackBar(content: Text('${recipe.name} saved to Cocktails')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barAsync = ref.watch(barIngredientsProvider);
    final pantryAsync = ref.watch(pantryIngredientsProvider);

    return barAsync.when(
      data: (allIngredients) {
        final inBar = allIngredients.where((i) => i.inMyBar).toList();
        final pantry = pantryAsync.asData?.value ?? const <PantryIngredient>[];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MIX1: what can I make tonight
              Text(
                'What can I make tonight?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Ranked by stock on hand; close substitutes count (with notes)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (inBar.isEmpty)
                Text(
                  'Mark bottles in My Bar to see makeable drinks.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: _loadingMakeable
                      ? null
                      : () => _loadMakeable(allIngredients, pantry),
                  icon: _loadingMakeable
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.checklist),
                  label: Text(
                    _makeable == null ? 'Rank my cocktails' : 'Refresh ranking',
                  ),
                ),
                if (_makeable != null) ...[
                  const SizedBox(height: 8),
                  if (_makeable!.isEmpty)
                    const Text('No cocktail recipes with ingredients found.')
                  else
                    ..._makeable!.take(8).map((s) {
                      final withSubs = s.isMakeableWithSubs;
                      final badge = s.isMakeable
                          ? (withSubs ? 'Ready*' : 'Ready')
                          : 'Need ${s.missingCount}';
                      final subLine = s.substitutesUsed.isEmpty
                          ? null
                          : s.substitutesUsed
                                .take(2)
                                .map(
                                  (u) =>
                                      '${u.using}→${u.needed} (${(u.confidence * 100).round()}%)',
                                )
                                .join(' · ');
                      final body = s.isMakeable
                          ? (withSubs
                                ? 'On hand with substitutes: $subLine'
                                : 'All ${s.haveCount} ingredients on hand')
                          : 'Have ${s.haveCount} · missing: ${s.missingNames.take(3).join(', ')}'
                                '${s.missingNames.length > 3 ? '...' : ''}'
                                '${subLine == null ? '' : '\nSubs: $subLine'}';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onTap: () => context.push(
                          AppRoutes.cocktailRecipe,
                          extra: s.recipe,
                        ),
                        leading: Icon(
                          s.isMakeable
                              ? (withSubs
                                    ? Icons.swap_horiz
                                    : Icons.check_circle)
                              : Icons.radio_button_unchecked,
                          color: s.isMakeable
                              ? SisuColors.completedBackground
                              : Colors.grey,
                        ),
                        title: Text(s.recipe.name),
                        subtitle: Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          badge,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: s.isMakeable
                                ? SisuColors.completedBackground
                                : Colors.orange.shade800,
                          ),
                        ),
                      );
                    }),
                ],
              ],
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Invent a drink',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'What vibe are you after?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _cocktailVibes.map((vibe) {
                  final selected = _selectedVibes.contains(vibe);
                  return FilterChip(
                    label: Text(vibe),
                    selected: selected,
                    selectedColor: SisuColors.completedBackground.withValues(
                      alpha: 0.25,
                    ),
                    checkmarkColor: SisuColors.completedBackground,
                    onSelected: (v) => setState(
                      () => v
                          ? _selectedVibes.add(vibe)
                          : _selectedVibes.remove(vibe),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Occasion (optional)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: MixologistService.occasionVibes.keys.map((occ) {
                  final selected = _selectedOccasion == occ;
                  return FilterChip(
                    label: Text(occ),
                    selected: selected,
                    selectedColor: Colors.deepPurple.withValues(alpha: 0.15),
                    checkmarkColor: Colors.deepPurple,
                    onSelected: (v) =>
                        setState(() => _selectedOccasion = v ? occ : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // MIX3: strength / glassware / crew size
              Text('Strength', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              SegmentedButton<CocktailStrength>(
                segments: CocktailStrength.values
                    .map((s) => ButtonSegment(value: s, label: Text(s.label)))
                    .toList(),
                selected: {_strength},
                onSelectionChanged: (set) =>
                    setState(() => _strength = set.first),
              ),
              const SizedBox(height: 12),
              Text('Glassware', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: MixologistService.glasswareOptions.map((g) {
                  final selected = _glassware == g;
                  return FilterChip(
                    label: Text(g),
                    selected: selected,
                    selectedColor: Colors.blueGrey.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _glassware = g),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Servings',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _servings > 1
                        ? () => setState(() => _servings--)
                        : null,
                  ),
                  Text(
                    '$_servings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _servings < 12
                        ? () => setState(() => _servings++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (inBar.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.liquor_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add ingredients to your bar first',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swipe right on any ingredient in the My Bar tab',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  '${inBar.length} ingredient${inBar.length == 1 ? "" : "s"} in your bar',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating
                        ? null
                        : () => _generate(allIngredients),
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text(
                      _suggestion == null
                          ? 'Suggest a Cocktail'
                          : 'Try Another',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: SisuColors.completedBackground,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              if (_isGenerating) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_suggestion != null) ...[
                const SizedBox(height: 20),
                _CocktailSuggestionCard(
                  suggestion: _suggestion!,
                  onSave: () => _saveAsRecipe(context),
                  onRetry: inBar.isEmpty
                      ? null
                      : () => _generate(allIngredients),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _CocktailSuggestionCard extends ConsumerWidget {
  final CocktailSuggestion suggestion;
  final VoidCallback onSave;
  final VoidCallback? onRetry;

  const _CocktailSuggestionCard({
    required this.suggestion,
    required this.onSave,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_bar, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    suggestion.technique.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    suggestion.glassware,
                    style: const TextStyle(fontSize: 11),
                  ),
                  avatar: const Icon(Icons.local_bar_outlined, size: 14),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    suggestion.strengthLabel,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (suggestion.servings > 1)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '${suggestion.servings} servings',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                if (suggestion.estimatedAbvPercent != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '~${suggestion.estimatedAbvPercent!.toStringAsFixed(0)}% ABV',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ingredients',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...suggestion.ingredients.map((i) {
              final unitSystem = ref.watch(unitSystemProvider);
              final qtyLabel = i.quantity > 0
                  ? UnitConverter.format(
                      i.quantity,
                      i.unit,
                      unitSystem,
                      preferBarUnits: true,
                    )
                  : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    if (qtyLabel.isNotEmpty)
                      Text(
                        '$qtyLabel  ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    Expanded(child: Text(i.name)),
                    if (i.optional)
                      Text(
                        'optional',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Instructions',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.instructions,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.rationale,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pairs well with',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  MixologistService.foodPairings(
                        suggestion.ingredients.isNotEmpty
                            ? suggestion.ingredients.first.name
                            : '',
                      )
                      .map(
                        (food) => Chip(
                          label: Text(
                            food,
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Try Another'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Save Recipe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SisuColors.completedBackground,
                      foregroundColor: Colors.white,
                    ),
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

// ── Syrups & House Mixes tab ──────────────────────────────────────────────────

class _SyrupsTab extends ConsumerStatefulWidget {
  const _SyrupsTab();

  @override
  ConsumerState<_SyrupsTab> createState() => _SyrupsTabState();
}

class _SyrupsTabState extends ConsumerState<_SyrupsTab> {
  // #136: House had no sort of any kind; a simple local A-Z/Z-A toggle
  // matches the level of functionality My Bar/Cocktails already have.
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider('syrup'));
    return recipesAsync.when(
      data: (recipesData) {
        if (recipesData.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.science_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No house recipes yet'),
                SizedBox(height: 4),
                Text(
                  'Tap + to add a syrup or house mix',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        final recipes = List.of(recipesData)
          ..sort(
            (a, b) => _sortAscending
                ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
                : b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Spacer(),
                  ActionChip(
                    avatar: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                    ),
                    label: Text(_sortAscending ? 'Name A–Z' : 'Name Z–A'),
                    onPressed: () =>
                        setState(() => _sortAscending = !_sortAscending),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: recipes.length,
                itemBuilder: (_, i) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.science,
                      size: 36,
                      color: Colors.deepPurple,
                    ),
                    title: Text(recipes[i].name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recipes[i].description ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (recipes[i].flavorProfiles.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              for (final t in recipes[i].flavorProfiles.take(3))
                                TagChip(label: t, color: Colors.orange[700]!),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: recipes[i].prepMinutes != null
                        ? Text(
                            '${recipes[i].prepMinutes}m',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                    onTap: () => context.push(
                      AppRoutes.cocktailRecipe,
                      extra: recipes[i],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Add/Edit cocktail recipe dialog ──────────────────────────────────────────

/// Bundles [AddEditRecipeDialog]'s constructor args for passing through
/// GoRouter's `extra` to the shared `recipeEditor` named route.
class AddEditRecipeArgs {
  final RecipeType recipeType;
  final void Function(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
    List<RecipeIngredient> removedIngredients,
  )
  onSave;
  final Recipe? existingRecipe;
  final List<RecipeIngredient> existingIngredients;
  final String? prefillName;
  final String? prefillInstructions;

  const AddEditRecipeArgs({
    required this.recipeType,
    required this.onSave,
    this.existingRecipe,
    this.existingIngredients = const [],
    this.prefillName,
    this.prefillInstructions,
  });
}

class AddEditRecipeDialog extends StatefulWidget {
  final RecipeType recipeType;
  final void Function(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
    List<RecipeIngredient> removedIngredients,
  )
  onSave;
  final Recipe? existingRecipe;
  final List<RecipeIngredient> existingIngredients;
  final String? prefillName;
  final String? prefillInstructions;

  const AddEditRecipeDialog({
    super.key,
    required this.recipeType,
    required this.onSave,
    this.existingRecipe,
    this.existingIngredients = const [],
    this.prefillName,
    this.prefillInstructions,
  });

  @override
  State<AddEditRecipeDialog> createState() => _AddEditRecipeDialogState();
}

class _AddEditRecipeDialogState extends State<AddEditRecipeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final List<RecipeIngredient> _ingredients = [];
  final List<RecipeIngredient> _removedIngredients = [];
  String? _cookingMethod;
  final Set<String> _selectedCuisineTags = {};
  final Set<String> _selectedFlavorTags = {};
  List<String> _cuisineOptions = List.of(TagLibraryService.suggestedCuisine);
  List<String> _flavorOptions = List.of(TagLibraryService.suggestedFlavor);
  String? _localPath;
  String? _imageAsset;

  static const _methodOptions = [
    'Stovetop',
    'Grill',
    'Oven',
    'Pan-fry',
    'Wok',
    'Steam',
    'One-pot',
    'Slow-cook',
    'Pressure-cook',
    'Raw / No-cook',
    'Deep-fry',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingRecipe != null) {
      _nameController.text = widget.existingRecipe!.name;
      _descriptionController.text = widget.existingRecipe!.description ?? '';
      _instructionsController.text = widget.existingRecipe!.instructions ?? '';
      _cookingMethod = widget.existingRecipe!.cookingMethod;
      _selectedCuisineTags.addAll(widget.existingRecipe!.cuisine);
      _selectedFlavorTags.addAll(widget.existingRecipe!.flavorProfiles);
      _localPath = widget.existingRecipe!.localPath;
      _imageAsset = widget.existingRecipe!.imageAsset;
    } else {
      _nameController.text = widget.prefillName ?? '';
      _instructionsController.text = widget.prefillInstructions ?? '';
    }
    _ingredients.addAll(widget.existingIngredients);
    _loadTagOptions();
  }

  Future<void> _pickRecipeImage() async {
    final picked = await pickPhotoFromCameraOrGallery(context);
    if (picked == null || !mounted) return;
    setState(() => _localPath = picked.path);
  }

  void _clearRecipeImage() {
    setState(() => _localPath = null);
  }

  Widget _recipePhotoFallback({
    required bool isDark,
    required bool isCocktail,
  }) {
    return Container(
      color: isDark ? Colors.white12 : Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        isCocktail ? Icons.local_bar : Icons.restaurant,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Future<void> _loadTagOptions() async {
    final lib = TagLibraryService.instance;
    final cuisine = await lib.options(
      TagKind.cuisine,
      extra: _selectedCuisineTags,
    );
    final flavor = await lib.options(
      TagKind.flavor,
      extra: _selectedFlavorTags,
    );
    if (!mounted) return;
    setState(() {
      _cuisineOptions = cuisine;
      _flavorOptions = flavor;
    });
  }

  Future<void> _onNovelTag(TagKind kind, String tag) async {
    await TagLibraryService.instance.remember(kind, tag);
    if (!mounted) return;
    await _loadTagOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingRecipe != null;
    final label = switch (widget.recipeType) {
      RecipeType.cocktail => 'Cocktail',
      RecipeType.syrup => 'House Recipe',
      _ => 'Recipe',
    };
    final isCocktail = widget.recipeType == RecipeType.cocktail;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit $label' : 'Add $label'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Photo preview + camera / gallery (cocktails, menus, house recipes)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _localPath != null && File(_localPath!).existsSync()
                          ? Image.file(
                              File(_localPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _recipePhotoFallback(
                                isDark: isDark,
                                isCocktail: isCocktail,
                              ),
                            )
                          : SmartImage(
                              assetName: _imageAsset,
                              userPhotoPath: null,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              customFallback: _recipePhotoFallback(
                                isDark: isDark,
                                isCocktail: isCocktail,
                              ),
                            ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_localPath != null) ...[
                              _RecipePhotoActionButton(
                                icon: Icons.hide_image_outlined,
                                tooltip: 'Remove photo',
                                onTap: _clearRecipeImage,
                              ),
                              const SizedBox(width: 8),
                            ],
                            _RecipePhotoActionButton(
                              icon: Icons.add_a_photo,
                              tooltip: 'Camera or gallery',
                              onTap: _pickRecipeImage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '$label Name',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              if (widget.recipeType == RecipeType.menu) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _cookingMethod,
                  decoration: const InputDecoration(
                    labelText: 'Cooking method',
                    border: OutlineInputBorder(),
                  ),
                  items: _methodOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _cookingMethod = v),
                ),
              ],
              if (isCocktail || widget.recipeType == RecipeType.menu) ...[
                const SizedBox(height: 16),
                TagCombobox(
                  label: isCocktail
                      ? 'Cuisine / style tags'
                      : 'Cuisine / course tags',
                  helperText:
                      'Pick from the list for consistency, or type a new tag',
                  options: _cuisineOptions,
                  selected: _selectedCuisineTags,
                  onChanged: (s) => setState(() {
                    _selectedCuisineTags
                      ..clear()
                      ..addAll(s);
                  }),
                  onNovelTag: (t) => _onNovelTag(TagKind.cuisine, t),
                ),
                const SizedBox(height: 16),
                TagCombobox(
                  label: 'Flavor profiles',
                  helperText:
                      'Type to filter; a new phrase is saved for next time',
                  options: _flavorOptions,
                  selected: _selectedFlavorTags,
                  onChanged: (s) => setState(() {
                    _selectedFlavorTags
                      ..clear()
                      ..addAll(s);
                  }),
                  onNovelTag: (t) => _onNovelTag(TagKind.flavor, t),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Add ingredient',
                    icon: const Icon(Icons.add),
                    onPressed: _addIngredient,
                  ),
                ],
              ),
              if (_ingredients.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No ingredients yet — tap + to add',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              for (var i = 0; i < _ingredients.length; i++)
                _IngredientFormField(
                  key: ValueKey(_ingredients[i].supabaseId),
                  ingredient: _ingredients[i],
                  onRemove: () => setState(() {
                    final removed = _ingredients.removeAt(i);
                    if (widget.existingIngredients.contains(removed)) {
                      _removedIngredients.add(removed);
                    }
                  }),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: Text(isEdit ? 'Save changes' : 'Add $label'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(
        RecipeIngredient()
          ..supabaseId = 'temp_${DateTime.now().millisecondsSinceEpoch}'
          ..recipeSupabaseId = 'temp'
          ..name = '',
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final isCocktail = widget.recipeType == RecipeType.cocktail;
    final isMenu = widget.recipeType == RecipeType.menu;
    final recipe = Recipe()
      ..supabaseId =
          widget.existingRecipe?.supabaseId ??
          'user_${DateTime.now().millisecondsSinceEpoch}'
      ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
      ..name = _nameController.text
      ..description = _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text
      ..instructions = _instructionsController.text.isEmpty
          ? null
          : _instructionsController.text
      ..cuisine = (isCocktail || isMenu)
          ? dedupeStrings(_selectedCuisineTags)
          : (widget.existingRecipe?.cuisine ?? [])
      ..flavorProfiles = (isCocktail || isMenu)
          ? dedupeStrings(_selectedFlavorTags)
          : (widget.existingRecipe?.flavorProfiles ?? [])
      ..cookingMethod = isMenu ? _cookingMethod : null
      ..recipeType = switch (widget.recipeType) {
        RecipeType.cocktail => 'cocktail',
        RecipeType.syrup => 'syrup',
        _ => 'menu',
      }
      ..isBundled = widget.existingRecipe?.isBundled ?? false
      ..isFavourite = widget.existingRecipe?.isFavourite ?? false
      ..imageAsset = _imageAsset
      ..localPath = _localPath
      ..glassware = widget.existingRecipe?.glassware
      ..story = widget.existingRecipe?.story
      ..prepMinutes = widget.existingRecipe?.prepMinutes;

    for (var i = 0; i < _ingredients.length; i++) {
      _ingredients[i]
        ..recipeSupabaseId = recipe.supabaseId
        ..sortOrder = i;
    }

    // Persist any selected tags into the shared library for next session.
    TagLibraryService.instance.rememberAll(TagKind.cuisine, recipe.cuisine);
    TagLibraryService.instance.rememberAll(
      TagKind.flavor,
      recipe.flavorProfiles,
    );

    widget.onSave(recipe, List.of(_ingredients), List.of(_removedIngredients));
  }
}

/// High-contrast photo action on the recipe/cocktail image hero.
class _RecipePhotoActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RecipePhotoActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SisuColors.completedBackground,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const _StarRow({required this.rating, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: size,
          color: Colors.amber[700],
        ),
      ),
    );
  }
}

class _AddTastingDialog extends StatefulWidget {
  const _AddTastingDialog();

  @override
  State<_AddTastingDialog> createState() => _AddTastingDialogState();
}

class _AddTastingDialogState extends State<_AddTastingDialog> {
  int _rating = 3;
  final _notesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Tasting Note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating'),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    size: 32,
                    color: Colors.amber[700],
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Where (optional)',
                hintText: 'e.g. Sundowner at anchor, Barbados',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Tasting impressions, tweaks…',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final record = TastingRecord()
              ..tastedAt = DateTime.now()
              ..rating = _rating
              ..location = _locationCtrl.text.trim().isEmpty
                  ? null
                  : _locationCtrl.text.trim()
              ..notes = _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim();
            Navigator.of(context).pop(record);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

void _showTechniqueSheet(BuildContext context, String technique) {
  final guides =
      <
        String,
        ({
          IconData icon,
          String equipment,
          List<String> steps,
          List<String> tips,
        })
      >{
        'Shake': (
          icon: Icons.water_drop_outlined,
          equipment: 'Cocktail shaker · strainer · ice',
          steps: [
            'Fill shaker two-thirds with ice',
            'Add all ingredients',
            'Shake hard for 10–15 seconds until the shaker is frosty',
            'Double-strain into a chilled glass',
          ],
          tips: [
            'Dilution is a feature — shake until you feel the cold',
            'Never shake sparkling ingredients — add them after pouring',
          ],
        ),
        'Stir': (
          icon: Icons.rotate_right,
          equipment: 'Mixing glass · bar spoon · Hawthorne strainer · ice',
          steps: [
            'Fill mixing glass with ice',
            'Add all ingredients',
            'Stir smoothly for 20–30 rotations (about 30 seconds)',
            'Strain into a chilled glass',
          ],
          tips: [
            'Stirring chills without aeration — keeps spirits silky and clear',
            'Over-stirring dilutes; under-stirring leaves it too cold and harsh',
          ],
        ),
        'Build': (
          icon: Icons.layers_outlined,
          equipment: 'Serving glass · ice · bar spoon',
          steps: [
            'Add ice to the serving glass',
            'Pour spirits first, then mixers',
            'Stir briefly to combine',
            'Garnish and serve',
          ],
          tips: [
            'Add carbonated mixers last — pour gently down the inside of the glass',
            'For layered drinks, pour over the back of a spoon',
          ],
        ),
      };

  final guide = guides[technique];
  if (guide == null) return;

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(guide.icon, size: 28, color: Colors.deepPurple),
              const SizedBox(width: 10),
              Text(
                technique,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Equipment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(guide.equipment),
          const SizedBox(height: 16),
          const Text('Steps', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...guide.steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}.  ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(child: Text(e.value)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tips', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...guide.tips.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•  ',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(child: Text(t)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _IngredientFormField extends StatefulWidget {
  final RecipeIngredient ingredient;
  final VoidCallback onRemove;
  const _IngredientFormField({
    super.key,
    required this.ingredient,
    required this.onRemove,
  });

  @override
  State<_IngredientFormField> createState() => _IngredientFormFieldState();
}

class _IngredientFormFieldState extends State<_IngredientFormField> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  String? _unit;

  /// Metric storage units first; imperial aliases accepted then converted.
  static const _units = [
    '', 'ml', 'g', 'L', 'kg', 'dash', 'splash',
    'pieces', 'bottle', 'can', 'cloves', 'whole',
    // Imperial (converted to metric on change)
    'oz', 'fl oz', 'cup', 'tbsp', 'tsp', 'lb',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.ingredient.name;
    _qtyCtrl.text = widget.ingredient.quantity != null
        ? '${widget.ingredient.quantity}'
        : '';
    _unit = widget.ingredient.unit ?? '';
  }

  void _applyMetricQtyUnit() {
    final rawQty = double.tryParse(_qtyCtrl.text.trim());
    final rawUnit = (_unit == null || _unit!.isEmpty) ? null : _unit;
    final (qty, unit) = UnitConverter.normalizePair(rawQty, rawUnit);
    widget.ingredient.quantity = qty;
    widget.ingredient.unit = unit;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                    ),
                    onChanged: (v) => widget.ingredient.name = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _applyMetricQtyUnit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _unit = v);
                      _applyMetricQtyUnit();
                    },
                  ),
                ),
              ],
            ),
            // Wrap avoids horizontal overflow next to Optional / Garnish.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      value: widget.ingredient.isOptional,
                      onChanged: (v) => setState(
                        () => widget.ingredient.isOptional = v ?? false,
                      ),
                    ),
                    const Text('Optional'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      value: widget.ingredient.isGarnish,
                      onChanged: (v) => setState(
                        () => widget.ingredient.isGarnish = v ?? false,
                      ),
                    ),
                    const Text('Garnish'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── BC7: Build a Round (batch scaler) ────────────────────────────────────────

class CocktailBatchScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const CocktailBatchScreen({super.key, required this.recipe});

  @override
  ConsumerState<CocktailBatchScreen> createState() =>
      CocktailBatchScreenState();
}

class CocktailBatchScreenState extends ConsumerState<CocktailBatchScreen> {
  late Recipe _selectedRecipe;
  int _count = 4;

  @override
  void initState() {
    super.initState();
    _selectedRecipe = widget.recipe;
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider('cocktail'));
    final ingredientsAsync = ref.watch(
      recipeIngredientsProvider(_selectedRecipe.supabaseId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Build a Round')),
      body: Column(
        children: [
          // Cocktail picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: recipesAsync.when(
              data: (recipes) => InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Cocktail',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButton<Recipe>(
                  value: recipes.firstWhere(
                    (r) => r.supabaseId == _selectedRecipe.supabaseId,
                    orElse: () => _selectedRecipe,
                  ),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: recipes
                      .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.name)),
                      )
                      .toList(),
                  onChanged: (r) {
                    if (r != null) setState(() => _selectedRecipe = r);
                  },
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
          // Drink count stepper
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Drinks:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  onPressed: _count > 1 ? () => setState(() => _count--) : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_count',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  onPressed: _count < 50
                      ? () => setState(() => _count++)
                      : null,
                ),
                const Spacer(),
                Text(
                  'Total batch',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scaled ingredient list
          Expanded(
            child: ingredientsAsync.when(
              data: (ingredients) {
                final nonGarnish = ingredients
                    .where((i) => !i.isGarnish)
                    .toList();
                final garnishes = ingredients
                    .where((i) => i.isGarnish)
                    .toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (nonGarnish.isNotEmpty) ...[
                      Text(
                        'Ingredients',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...nonGarnish.map(
                        (i) =>
                            _BatchIngredientRow(ingredient: i, count: _count),
                      ),
                    ],
                    if (garnishes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Garnishes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...garnishes.map(
                        (i) =>
                            _BatchIngredientRow(ingredient: i, count: _count),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchIngredientRow extends ConsumerWidget {
  final RecipeIngredient ingredient;
  final int count;
  const _BatchIngredientRow({required this.ingredient, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitSystem = ref.watch(unitSystemProvider);
    final formatted = UnitConverter.format(
      ingredient.quantity,
      ingredient.unit,
      unitSystem,
      scale: count.toDouble(),
      preferBarUnits: true,
    );
    final qtyText = formatted.isNotEmpty
        ? formatted
        : (ingredient.isOptional ? 'optional' : '—');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ingredient.name,
              style: ingredient.isOptional
                  ? TextStyle(color: Colors.grey[600])
                  : null,
            ),
          ),
          Text(
            qtyText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
