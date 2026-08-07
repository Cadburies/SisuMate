import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_router.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/import_export.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/pantry_ingredient_provider.dart';
import '../../models/models.dart';
import '../components/swipeable_list_item.dart';
import '../components/themed_state_tile.dart';
import '../components/item_detail_shell.dart';
import '../../core/di.dart';
import '../../services/error_log_service.dart';
import '../../core/colors.dart';
import '../../core/units.dart';
import '../../services/revenuecat_service.dart';
import '../../services/import_service.dart';
import '../../services/email_service.dart';
import '../../services/smart_shopping_service.dart';
import 'customs_check_dialog.dart';

enum SortOption { original, name, completed, price, priority }

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortOption = SortOption.original;
  bool _sortAscending = true;
  bool _didBackfillPrices = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // One-shot: fill null shopping prices from bar/pantry seed catalog.
    if (!_didBackfillPrices) {
      _didBackfillPrices = true;
      ref
          .read(shoppingRepositoryProvider)
          .backfillMissingPricesFromCatalog();
    }
  }

  Future<String> _exportShopping() async {
    final repo = ref.read(shoppingRepositoryProvider);
    final cats = await repo.watchCategories().first;
    final items = <ImportedShoppingItem>[];
    for (final c in cats) {
      for (final it in await repo.watchItems(c.supabaseId).first) {
        if (it.isHidden) continue; // export visible cart only
        items.add(ImportedShoppingItem(it, c.name));
      }
    }
    return ImportService.exportShopping(
      items,
      unitSystem: ref.read(unitSystemProvider),
    );
  }

  /// Current item names for the pre-import "did you mean X?" check (BAI6) —
  /// same visibility filter as the dedupe scan in [_importShopping].
  Future<List<String>> _existingShoppingNames() async {
    final repo = ref.read(shoppingRepositoryProvider);
    final cats = await repo.watchCategories().first;
    final names = <String>[];
    for (final c in cats) {
      names.addAll((await repo.watchItems(c.supabaseId).first)
          .where((i) => !i.isHidden)
          .map((i) => i.name));
    }
    return names;
  }

  Future<ImportPersistResult> _importShopping(ImportBatch batch) async {
    final repo = ref.read(shoppingRepositoryProvider);
    final existingCats = await repo.watchCategories().first;
    // Match categories by name (case-insensitive), creating any that are new.
    final byName = {
      for (final c in existingCats) c.name.toLowerCase(): c.supabaseId
    };
    // Flat list of pending/all items for content-key upsert (IMP2).
    final existingItems = <ShoppingItem>[];
    for (final cat in existingCats) {
      existingItems.addAll(
        (await repo.watchItems(cat.supabaseId).first)
            .where((i) => !i.isHidden),
      );
    }
    var inserted = 0;
    var updated = 0;
    for (final rec in batch.shoppingItems) {
      final catName = (rec.categoryName == null || rec.categoryName!.isEmpty)
          ? 'Imported'
          : rec.categoryName!;
      var catId = byName[catName.toLowerCase()];
      if (catId == null) {
        final cat = ShoppingCategory()
          ..supabaseId =
              'imp_cat_${DateTime.now().millisecondsSinceEpoch}_${byName.length}'
          ..name = catName
          ..sortOrder = existingCats.length + byName.length;
        await repo.addCategory(cat);
        catId = cat.supabaseId;
        byName[catName.toLowerCase()] = catId;
      }
      rec.item.categorySupabaseId = catId;
      final match = ImportService.matchExisting(
        existing: existingItems,
        incomingId: rec.item.supabaseId,
        idOf: (e) => e.supabaseId,
        contentKeyOf: ImportService.contentKeyShopping,
        incomingContentKey: ImportService.contentKeyShopping(rec.item),
      );
      if (match != null) {
        rec.item.supabaseId = match.supabaseId;
        rec.item.id = match.id;
        await repo.updateItem(rec.item);
        updated++;
      } else {
        await repo.addItem(rec.item);
        existingItems.add(rec.item);
        inserted++;
      }
    }
    return ImportPersistResult(inserted: inserted, updated: updated);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(shoppingCategoriesProvider);
    final isProAsync = ref.watch(isProProvider);
    final isPro = isProAsync.value ?? false;

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Shopping & Spares',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                actionsBuilder: (color) => [
                  IconButton(
                    icon: Icon(Icons.import_export, color: color),
                    tooltip: 'Import / Export',
                    onPressed: () => showImportExportSheet(
                      context,
                      ModuleImportExport(
                        kind: ImportService.kindShopping,
                        label: 'Shopping',
                        fileBaseName: 'sisu_shopping',
                        exportCurrent: _exportShopping,
                        existingNames: _existingShoppingNames,
                        persist: _importShopping,
                      ),
                      isPro: isPro,
                      onProRequired: () =>
                          RevenueCatService().showPaywall(context),
                              ref: ref,
                    ),
                  ),
                ],
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              // Sort options
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: SortOption.values.map((option) {
                    final isSelected = _sortOption == option;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getSortLabel(option)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (isSelected) {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortOption = option;
                              _sortAscending = true;
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => _buildOriginCategoriesView(categories),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading shopping data: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isProAsync.when(
        data: (isPro) => FloatingActionButton(
          tooltip: 'Add item',
          onPressed: () {
            if (!isPro) {
              _showProRequiredDialog(context);
            } else {
              _showAddItemDialog(context);
            }
          },
          child: const Icon(Icons.add),
        ),
        loading: () => const FloatingActionButton(
          tooltip: 'Add item',
          onPressed: null,
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => const FloatingActionButton(
          tooltip: 'Add item',
          onPressed: null,
          child: Icon(Icons.error),
        ),
      ),
      endDrawer: _buildEndDrawer(),
    );
  }

  Future<void> _completeShoppingRun(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete shopping run?'),
        content: const Text(
          'This permanently removes every bought (green) item from the '
          'shopping list so you start clean next trip.\n\n'
          'Pending (not bought) items stay. Stock in My Bar / My Pantry is '
          'not changed.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear bought'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final n =
        await ref.read(shoppingRepositoryProvider).clearBoughtItems();
    if (context.mounted) navigator.pop(); // close drawer
    messenger.showSnackBar(SnackBar(
      content: Text(n == 0
          ? 'No bought items to clear'
          : 'Cleared $n bought item${n == 1 ? '' : 's'}'),
    ));
  }

  Widget _buildEndDrawer() {
    return Drawer(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DrawerHeaderWidget(title: 'Filters & Options'),
                      const Divider(),

                      // Show Hidden Items Toggle (shopping-specific)
                      Consumer(
                        builder: (context, ref, child) {
                          final settingsAsync = ref.watch(userSettingsProvider);
                          return settingsAsync.when(
                            data: (settings) => SwitchListTile(
                              title: const Text('Show Hidden Items'),
                              subtitle: const Text('Display soft-deleted items'),
                              value: settings?.showHiddenItems ?? false,
                              onChanged: (value) async {
                                final updatedSettings = (settings ?? UserSettings())..showHiddenItems = value;
                                final repository = ref.read(userSettingsRepositoryProvider);
                                await repository.updateSettings(updatedSettings);
                                ref.invalidate(userSettingsProvider);
                              },
                            ),
                            loading: () => const ListTile(
                              title: Text('Loading settings...'),
                              leading: CircularProgressIndicator(),
                            ),
                            error: (e, _) => ListTile(
                              title: const Text('Settings Error'),
                              subtitle: Text(e.toString()),
                            ),
                          );
                        },
                      ),
                      const Divider(),

                      SectionHeader(title: 'Share'),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email All Lists'),
                        subtitle: const Text('Send every section in one email'),
                        onTap: () => _emailAllLists(context, ref),
                      ),
                      const Divider(),

                      SectionHeader(title: 'Shopping run'),
                      ListTile(
                        leading: Icon(Icons.shopping_cart_checkout,
                            color: SisuColors.completedBackground),
                        title: const Text('Complete shopping run'),
                        subtitle: const Text(
                            'Remove all bought (green) items — ready for next trip'),
                        onTap: () => _completeShoppingRun(context, ref),
                      ),
                      const Divider(),

                      SectionHeader(title: 'Options'),
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



  Widget _buildOriginCategoriesView(List<ShoppingCategory> categories) {
    // Group items by origin; trip estimate = sum of pending line totals only.
    final originGroups = <String, List<ShoppingItem>>{};
    final originTotals = <String, double>{};
    var tripTotal = 0.0;
    var tripPendingCount = 0;
    var tripPricedCount = 0;

    for (final category in categories) {
      final itemsAsync =
          ref.watch(shoppingItemsByCategoryProvider(category.supabaseId));
      itemsAsync.whenData((items) {
        for (final item in items) {
          if (item.isHidden) continue;
          final origin = item.origin;
          originGroups.putIfAbsent(origin, () => []).add(item);

          // Outstanding trip cost: pending (not bought) lines only.
          if (!item.isBought) {
            tripPendingCount++;
            final line = item.lineEstimate;
            if (line != null) {
              tripPricedCount++;
              tripTotal += line;
              originTotals[origin] = (originTotals[origin] ?? 0) + line;
            }
          }
        }
      });
    }

    if (originGroups.isEmpty) {
      return const Center(child: Text('No shopping items yet'));
    }

    final allItems = _allVisibleItems(categories);
    final ranked = _rankPassage(allItems);
    final scoreById = <String, int>{
      for (final r in ranked)
        if (r.item.supabaseId.isNotEmpty) r.item.supabaseId: r.score,
    };
    final topPending =
        ranked.where((r) => !r.item.isBought && r.score > 0).take(5).toList();

    return Column(
      children: [
        // BAI2: buy-before-passage heads-up from pantry / meal plan / season.
        if (topPending.isNotEmpty)
          Material(
            color: Theme.of(context)
                .colorScheme
                .tertiaryContainer
                .withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sailing_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Buy before passage',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _sortOption = SortOption.priority;
                          _sortAscending = false;
                        }),
                        child: const Text('Sort by priority'),
                      ),
                    ],
                  ),
                  for (final r in topPending)
                    Text(
                      '${r.item.name}'
                      '${r.reasons.isEmpty ? '' : ' — ${r.reasons.first}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        // Trip cost strip — predicted spend for outstanding items.
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.payments_outlined,
                    color: SisuColors.completedBackground),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip estimate (to buy)',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        tripPendingCount == 0
                            ? 'Nothing pending'
                            : tripPricedCount == 0
                                ? 'No prices yet — edit items or catalog'
                                : '\$${tripTotal.toStringAsFixed(2)}'
                                    ' · $tripPricedCount of $tripPendingCount priced',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: originGroups.length,
            itemBuilder: (context, index) {
              final origin = originGroups.keys.elementAt(index);
              final items = originGroups[origin]!;
              final total = originTotals[origin] ?? 0;

              return ShoppingOriginTile(
                origin: origin,
                totalBudget: total,
                items: items,
                searchQuery: _searchQuery,
                sortOption: _sortOption,
                sortAscending: _sortAscending,
                priorityScores: scoreById,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _emailAllLists(BuildContext context, WidgetRef ref) async {
    final categories = ref.read(shoppingCategoriesProvider).asData?.value ?? [];
    final originGroups = <String, List<ShoppingItem>>{};
    for (final category in categories) {
      final items =
          ref.read(shoppingItemsByCategoryProvider(category.supabaseId)).asData?.value ?? [];
      for (final item in items) {
        if (item.isHidden) continue;
        originGroups.putIfAbsent(item.origin, () => []).add(item);
      }
    }

    final settings = await ref.read(userSettingsProvider.future);
    if (!context.mounted) return;
    final boatName = settings?.boatName;

    final buffer = StringBuffer();
    for (final entry in originGroups.entries) {
      buffer.writeln('${_capitalizeOrigin(entry.key)}:');
      for (final item in entry.value) {
        buffer.writeln('- ${_formatItemLine(item)}');
      }
      buffer.writeln();
    }

    await EmailService.composeAndSend(
      context,
      ref,
      subject:
          boatName != null && boatName.isNotEmpty ? 'Shopping list for $boatName' : 'Shopping list',
      body: buffer.toString().trim(),
    );
  }

  String _capitalizeOrigin(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatItemLine(ShoppingItem item) {
    final parts = <String>[item.name];
    if (item.quantity > 1) parts.add('x${item.quantity}');
    if (item.notes != null && item.notes!.isNotEmpty) parts.add('(${item.notes})');
    return parts.join(' ');
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.original:
        return 'Original';
      case SortOption.name:
        return _sortAscending ? 'Name A-Z' : 'Name Z-A';
      case SortOption.completed:
        return _sortAscending ? 'Needed First' : 'Bought First';
      case SortOption.price:
        return _sortAscending ? 'Price Low-High' : 'Price High-Low';
      case SortOption.priority:
        return 'Passage priority';
    }
  }

  /// Flat cart across categories for BAI2 ranking (visible items only).
  List<ShoppingItem> _allVisibleItems(List<ShoppingCategory> categories) {
    final out = <ShoppingItem>[];
    for (final category in categories) {
      final items = ref
              .watch(shoppingItemsByCategoryProvider(category.supabaseId))
              .asData
              ?.value ??
          const <ShoppingItem>[];
      for (final item in items) {
        if (!item.isHidden) out.add(item);
      }
    }
    return out;
  }

  List<RankedShoppingItem> _rankPassage(List<ShoppingItem> items) {
    final pantry =
        ref.watch(pantryIngredientsProvider).asData?.value ?? const [];
    final plans = ref.watch(mealPlansProvider).asData?.value ?? const [];
    final ings =
        ref.watch(mealPlanIngredientsMapProvider).asData?.value ?? const {};
    return SmartShoppingService.rankForPassage(
      items: items,
      pantry: pantry,
      mealPlans: plans,
      ingredientsByRecipe: ings,
    );
  }

  void _showProRequiredDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sisu Mate Pro Required'),
        content: const Text(
          'Adding custom shopping items is a Pro feature. Upgrade to unlock editing, custom checklists, and cloud sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              RevenueCatService().showPaywall(context);
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    final priceController = TextEditingController();
    String selectedOrigin = 'spares';
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Shopping Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedOrigin, // ignore: deprecated_member_use - False positive, DropdownButtonFormField correctly uses 'value'
                  decoration: const InputDecoration(
                    labelText: 'Origin',
                    border: OutlineInputBorder(),
                  ),
                  items: ['galley', 'spares', 'bar', 'deck', 'engine', 'other']
                      .map((origin) => DropdownMenuItem(
                            value: origin,
                            child: Text(origin.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedOrigin = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Last Purchase Price (optional)',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Item name is required')),
                  );
                  return;
                }

                final item = ShoppingItem()
                  ..supabaseId = 'user_${DateTime.now().millisecondsSinceEpoch}'
                  // Must match a real category id (UI groups via category streams).
                  ..categorySupabaseId = 'cat-misc'
                  ..name = nameController.text.trim()
                  ..quantity = int.tryParse(quantityController.text) ?? 1
                  ..notes = notesController.text.trim().isEmpty ? null : notesController.text.trim()
                  ..origin = selectedOrigin
                  ..lastPurchasePrice = priceController.text.trim().isEmpty
                      ? null
                      : double.tryParse(priceController.text)
                  ..isBought = false
                  ..isHidden = false;

                try {
                  final repository = ref.read(shoppingRepositoryProvider);
                  await repository.addItem(item);
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('${item.name} added to shopping list')),
                  );
                } catch (e, st) {
                  unawaited(
                      ErrorLogService().logException(e, st, context: 'shopping_screen: addItem'));
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error adding item: $e')),
                  );
                }
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class ShoppingCategoryTile extends ConsumerWidget {
  final ShoppingCategory category;

  const ShoppingCategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch items for this category specifically
    final itemsAsync = ref.watch(
      shoppingItemsByCategoryProvider(category.supabaseId),
    );
    final settingsAsync = ref.watch(userSettingsProvider);

    return itemsAsync.when(
      data: (items) => settingsAsync.when(
        data: (settings) {
          final showHidden = settings?.showHiddenItems ?? false;
          final shownItems = items
              .where((item) => !item.isHidden || showHidden)
              .toList();

          return ExpansionTile(
            title: Text(category.name),
            children: shownItems
                .map((item) => ShoppingItemTile(item: item))
                .toList(),
          );
        },
        loading: () => const SizedBox(), // Wait for settings
        error: (e, _) => ListTile(title: Text('Error loading settings: $e')),
      ),
      loading: () => const ListTile(title: Text('Loading items...')),
      error: (e, _) => ListTile(title: Text('Error loading items: $e')),
    );
  }
}

class ShoppingOriginTile extends ConsumerWidget {
  final String origin;
  final double totalBudget;
  final List<ShoppingItem> items;
  final String searchQuery;
  final SortOption sortOption;
  final bool sortAscending;
  /// BAI2 passage scores keyed by shopping item supabaseId.
  final Map<String, int> priorityScores;

  // ignore: prefer_const_constructors_in_immutables
  ShoppingOriginTile({
    super.key,
    required this.origin,
    required this.totalBudget,
    required this.items,
    required this.searchQuery,
    required this.sortOption,
    required this.sortAscending,
    this.priorityScores = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final showHidden = settings?.showHiddenItems ?? false;

        // Filter items
        var filteredItems = items.where((item) {
          if (!showHidden && item.isHidden) return false;
          if (searchQuery.isNotEmpty) {
            return item.name.toLowerCase().contains(searchQuery) ||
                   (item.notes?.toLowerCase().contains(searchQuery) ?? false);
          }
          return true;
        }).toList();

        // Sort items
        filteredItems.sort((a, b) {
          int comparison;
          switch (sortOption) {
            case SortOption.original:
              comparison = a.id.compareTo(b.id);
              break;
            case SortOption.name:
              comparison = a.name.compareTo(b.name);
              break;
            case SortOption.completed:
              comparison = (a.isBought ? 1 : 0).compareTo(b.isBought ? 1 : 0);
              break;
            case SortOption.price:
              comparison = (a.lastPurchasePrice ?? 0).compareTo(b.lastPurchasePrice ?? 0);
              break;
            case SortOption.priority:
              final sa = priorityScores[a.supabaseId] ?? 0;
              final sb = priorityScores[b.supabaseId] ?? 0;
              comparison = sa.compareTo(sb);
              break;
          }
          return sortAscending ? comparison : -comparison;
        });

        return ExpansionTile(
          title: Slidable(
            startActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => _emailSection(context, ref, origin, filteredItems),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  icon: Icons.email_outlined,
                  label: 'Email',
                ),
              ],
            ),
            child: Row(
              children: [
                Text(_capitalize(origin)),
                const Spacer(),
                Text(
                  '\$${totalBudget.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          children: filteredItems.map((item) => ShoppingItemTile(item: item)).toList(),
        );
      },
      loading: () => const SizedBox(),
      error: (e, _) => ListTile(title: Text('Error loading settings: $e')),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  Future<void> _emailSection(BuildContext context, WidgetRef ref, String origin,
      List<ShoppingItem> items) async {
    final settings = await ref.read(userSettingsProvider.future);
    if (!context.mounted) return;
    final boatName = settings?.boatName;

    final buffer = StringBuffer();
    for (final item in items) {
      final parts = <String>[item.name];
      if (item.quantity > 1) parts.add('x${item.quantity}');
      if (item.notes != null && item.notes!.isNotEmpty) parts.add('(${item.notes})');
      buffer.writeln('- ${parts.join(' ')}');
    }

    final sectionName = _capitalize(origin);
    await EmailService.composeAndSend(
      context,
      ref,
      subject: boatName != null && boatName.isNotEmpty
          ? '$sectionName list for $boatName'
          : '$sectionName list',
      body: buffer.toString().trim(),
    );
  }
}

class ShoppingItemTile extends ConsumerWidget {
  final ShoppingItem item;

  const ShoppingItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(shoppingRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colour tells state (theme.md §6.5): hidden → stocked(bought) → shopping.
    final state = item.isHidden
        ? ItemListState.hidden
        : item.isBought
            ? ItemListState.stocked
            : ItemListState.shopping;
    final c = SisuColors.itemStateColors(isDark, state);

    // #309 — quantity is buy count (packs); unit is optional pack label
    // (e.g. "250ml bottle"), not a measure multiplier for price.
    final qtyParts = <String>[];
    if (item.quantity > 1) {
      qtyParts.add('×${item.quantity}');
    }
    if (item.unit != null && item.unit!.isNotEmpty) {
      qtyParts.add(item.unit!);
    }
    final qtyLine = qtyParts.isEmpty ? null : qtyParts.join(' ');

    final packPrice = item.lastPurchasePrice;
    final line = item.lineEstimate;
    String? priceLine;
    if (packPrice != null) {
      final pack = '\$${packPrice.toStringAsFixed(2)}';
      if (item.quantity > 1 && line != null) {
        priceLine = '$pack × ${item.quantity} = \$${line.toStringAsFixed(2)}';
      } else {
        priceLine = pack;
      }
    }
    final placeLine = (item.lastPurchasePlace != null &&
            item.lastPurchasePlace!.isNotEmpty)
        ? item.lastPurchasePlace
        : null;
    final tertiary = [
      ?priceLine,
      ?placeLine,
    ].join(' · ');

    final tile = SwipeableListItem(
      isHidden: item.isHidden,
      isCompleted: item.isBought,
      onComplete: () async {
        await repository.toggleBought(item);
      },
      onHide: () async {
        if (item.isHidden) {
          await repository.permanentlyDelete(item);
        } else {
          await repository.hideItem(item);
        }
      },
      onUnhide: item.isHidden
          ? () async {
              await repository.unhideItem(item);
            }
          : null,
      onEmail: () => _emailItem(context, ref, item),
      child: ThemedStateTile(
        state: state,
        leading: Icon(Icons.shopping_bag_outlined, color: c.desc),
        title: item.name,
        subtitle: qtyLine,
        tertiary: tertiary.isEmpty ? null : tertiary,
        onTap: () => _openDetail(context, ref),
      ),
    );
    // #228/#208: AI customs-check badge — a visually distinct entry point,
    // never mixed into the swipe-revealed Complete/Hide/Email actions above.
    return Stack(
      children: [
        tile,
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.deepPurple,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showDialog(
                context: context,
                builder: (_) => const CustomsCheckDialog(),
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref) {
    // Visible items across categories (same boat shopping list).
    final cats = ref.read(shoppingCategoriesProvider).asData?.value ?? [];
    final all = <ShoppingItem>[];
    for (final cat in cats) {
      final items = ref
              .read(shoppingItemsByCategoryProvider(cat.supabaseId))
              .asData
              ?.value ??
          [];
      all.addAll(items);
    }
    if (all.isEmpty) all.add(item);
    var index = all.indexWhere((i) => i.supabaseId == item.supabaseId);
    if (index < 0) {
      all.insert(0, item);
      index = 0;
    }
    context.push(
      AppRoutes.shoppingItemDetail,
      extra: (items: all, initialIndex: index),
    );
  }

  Future<void> _emailItem(BuildContext context, WidgetRef ref, ShoppingItem item) async {
    final parts = <String>[item.name];
    if (item.quantity > 1) parts.add('x${item.quantity}');
    if (item.notes != null && item.notes!.isNotEmpty) parts.add('(${item.notes})');
    await EmailService.composeAndSend(
      context,
      ref,
      subject: 'Shopping: ${item.name}',
      body: '- ${parts.join(' ')}',
    );
  }
}

/// UX5 swipeable shopping item detail.
class ShoppingItemDetailScreen extends ConsumerStatefulWidget {
  final List<ShoppingItem> items;
  final int initialIndex;

  const ShoppingItemDetailScreen({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  ConsumerState<ShoppingItemDetailScreen> createState() =>
      _ShoppingItemDetailScreenState();
}

class _ShoppingItemDetailScreenState
    extends ConsumerState<ShoppingItemDetailScreen> {
  late List<ShoppingItem> _items;
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<ShoppingItem>.from(widget.items);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _notesCtrl.dispose();
    _priceCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  ShoppingItem _item(int i) => _items[i];

  void _load(int i) {
    final it = _item(i);
    _nameCtrl.text = it.name;
    _qtyCtrl.text = it.quantity.toString();
    _unitCtrl.text = it.unit ?? '';
    _notesCtrl.text = it.notes ?? '';
    _priceCtrl.text = it.lastPurchasePrice?.toString() ?? '';
    _placeCtrl.text = it.lastPurchasePlace ?? '';
  }

  // #204: optional overrides let action buttons compute the *destination*
  // state's color (what a tap would move the item to) instead of the
  // current one, without duplicating this hidden/bought precedence logic.
  ItemListState _state(ShoppingItem it, {bool? isHidden, bool? isBought}) =>
      (isHidden ?? it.isHidden)
          ? ItemListState.hidden
          : (isBought ?? it.isBought)
              ? ItemListState.stocked
              : ItemListState.shopping;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = ref.read(shoppingRepositoryProvider);

    return ItemDetailShell(
      itemCount: _items.length,
      initialIndex: widget.initialIndex.clamp(0, _items.length - 1),
      titleForIndex: (i) => _item(i).name,
      subtitleForIndex: (i) =>
          '${_item(i).origin} · ${i + 1} of ${_items.length}',
      stateColorForIndex: (i) =>
          SisuColors.itemStateColors(isDark, _state(_item(i))).bg,
      historyForIndex: (i) {
        final it = _item(i);
        final lines = <String>[
          'Last modified: ${it.lastModified.toLocal()}',
          'Origin: ${it.origin}',
        ];
        if (it.isBought) lines.add('Bought');
        if (it.isHidden) lines.add('Hidden');
        if (it.lastPurchasePrice != null) {
          lines.add(
              'Unit price: \$${it.lastPurchasePrice!.toStringAsFixed(2)}');
          final line = it.lineEstimate;
          if (line != null && it.quantity > 1) {
            lines.add('Line total: \$${line.toStringAsFixed(2)}');
          }
        }
        if (it.lastPurchasePlace != null &&
            it.lastPurchasePlace!.isNotEmpty) {
          lines.add('Place: ${it.lastPurchasePlace}');
        }
        return lines;
      },
      onSaveEdit: (i) async {
        final it = _item(i);
        it
          ..name = _nameCtrl.text.trim().isEmpty ? it.name : _nameCtrl.text.trim()
          ..quantity = int.tryParse(_qtyCtrl.text.trim()) ?? it.quantity
          ..unit =
              _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim()
          ..notes =
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()
          ..lastPurchasePrice = double.tryParse(_priceCtrl.text.trim())
          ..lastPurchasePlace = _placeCtrl.text.trim().isEmpty
              ? null
              : _placeCtrl.text.trim();
        await repo.updateItem(it);
        if (mounted) setState(() {});
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
        final it = _item(index);
        final c = SisuColors.itemStateColors(isDark, _state(it));
        if (isEditing) {
          return SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity')),
                TextField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unit')),
                TextField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Unit price (USD)',
                      prefixText: '\$',
                      helperText:
                          'Used for trip estimate; also updates bar/pantry catalog',
                    )),
                TextField(
                    controller: _placeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Store / location',
                      helperText: 'Where to buy / last purchased',
                    )),
                TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          );
        }
        final line = it.lineEstimate;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.name,
                  style: TextStyle(
                      color: c.title,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Qty: ${it.quantity}${it.unit != null ? ' ${it.unit}' : ''}',
                style: TextStyle(color: c.desc),
              ),
              if (it.lastPurchasePrice != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Unit price: \$${it.lastPurchasePrice!.toStringAsFixed(2)}',
                  style: TextStyle(color: c.desc, fontWeight: FontWeight.w600),
                ),
                if (line != null && it.quantity > 1)
                  Text(
                    'Line total: \$${line.toStringAsFixed(2)}',
                    style: TextStyle(color: c.desc),
                  ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'No price set — edit to add unit price for trip estimate',
                  style: TextStyle(color: c.desc, fontStyle: FontStyle.italic),
                ),
              ],
              if (it.lastPurchasePlace != null &&
                  it.lastPurchasePlace!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Location: ${it.lastPurchasePlace}',
                    style: TextStyle(color: c.desc)),
              ],
              if (it.notes != null && it.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(it.notes!, style: TextStyle(color: c.desc)),
              ],
              const SizedBox(height: 8),
              Text(
                it.isBought
                    ? 'Status: bought'
                    : it.isHidden
                        ? 'Status: hidden'
                        : 'Status: to buy',
                style: TextStyle(color: c.desc),
              ),
            ],
          ),
        );
      },
      actionsForIndex:
          (context, index, isEditing, startEdit, cancelEdit, saveEdit) {
        final it = _item(index);
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
        // #204: each toggle's button previews the state the tap moves *into*.
        final boughtDestination = SisuColors.itemStateColors(
            isDark, _state(it, isBought: !it.isBought));
        final hideDestination = SisuColors.itemStateColors(
            isDark, _state(it, isHidden: !it.isHidden));
        return [
          DetailAction(
            icon: it.isBought ? Icons.remove_shopping_cart : Icons.shopping_cart,
            label: it.isBought ? 'Unbuy' : 'Bought',
            onPressed: () async {
              await repo.toggleBought(it);
              if (mounted) setState(() {});
            },
            color: boughtDestination.bg,
            onColor: boughtDestination.title,
          ),
          if (!it.isHidden)
            DetailAction(
              icon: Icons.visibility_off,
              label: 'Hide',
              onPressed: () async {
                await repo.hideItem(it);
                if (mounted) setState(() {});
              },
              color: hideDestination.bg,
              onColor: hideDestination.title,
            )
          else ...[
            DetailAction(
              icon: Icons.undo,
              label: 'Unhide',
              onPressed: () async {
                await repo.unhideItem(it);
                if (mounted) setState(() {});
              },
              color: hideDestination.bg,
              onColor: hideDestination.title,
            ),
            DetailAction(
              icon: Icons.delete_forever,
              label: 'Delete',
              color: Colors.red,
              onPressed: () async {
                await repo.permanentlyDelete(it);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
          DetailAction(
            icon: Icons.edit,
            label: 'Edit',
            onPressed: () {
              _load(index);
              startEdit();
            },
          ),
        ];
      },
    );
  }
}
