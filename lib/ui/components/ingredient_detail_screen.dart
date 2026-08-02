import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../providers/bar_ingredient_provider.dart';
import '../../providers/pantry_ingredient_provider.dart';
import 'item_detail_shell.dart';
import 'common_drawer.dart';
import 'photo_source_picker.dart';

/// Kind of ingredient list driving [IngredientDetailScreen].
enum IngredientStockKind { bar, pantry }

/// UX5 PageView detail for Bar / Pantry ingredient lists.
class IngredientDetailScreen extends ConsumerStatefulWidget {
  final IngredientStockKind kind;
  final List<BarIngredient>? barItems;
  final List<PantryIngredient>? pantryItems;
  final int initialIndex;

  const IngredientDetailScreen.bar({
    super.key,
    required List<BarIngredient> items,
    required this.initialIndex,
  })  : kind = IngredientStockKind.bar,
        barItems = items,
        pantryItems = null;

  const IngredientDetailScreen.pantry({
    super.key,
    required List<PantryIngredient> items,
    required this.initialIndex,
  })  : kind = IngredientStockKind.pantry,
        pantryItems = items,
        barItems = null;

  @override
  ConsumerState<IngredientDetailScreen> createState() =>
      _IngredientDetailScreenState();
}

class _IngredientDetailScreenState
    extends ConsumerState<IngredientDetailScreen> {
  late List<BarIngredient> _bar;
  late List<PantryIngredient> _pantry;
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool get _isBar => widget.kind == IngredientStockKind.bar;
  int get _count => _isBar ? _bar.length : _pantry.length;

  String _name(int i) => _isBar ? _bar[i].name : _pantry[i].name;
  bool _inStock(int i) =>
      _isBar ? _bar[i].inMyBar : _pantry[i].inMyPantry;
  String? _photo(int i) =>
      _isBar ? _bar[i].localPhotoPath : _pantry[i].localPhotoPath;

  @override
  void initState() {
    super.initState();
    _bar = List<BarIngredient>.from(widget.barItems ?? const []);
    _pantry = List<PantryIngredient>.from(widget.pantryItems ?? const []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _placeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _loadEditors(int i) {
    if (_isBar) {
      final b = _bar[i];
      _nameCtrl.text = b.name;
      _priceCtrl.text = b.lastKnownPrice?.toString() ?? '';
      _placeCtrl.text = b.lastPurchasePlace ?? '';
      _notesCtrl.text = '';
    } else {
      final p = _pantry[i];
      _nameCtrl.text = p.name;
      _priceCtrl.text = p.lastKnownPrice?.toString() ?? '';
      _placeCtrl.text = p.lastPurchasePlace ?? '';
      _notesCtrl.text = p.unit ?? '';
    }
  }

  Future<void> _toggleStock(int i) async {
    if (_isBar) {
      await ref.read(barIngredientRepositoryProvider).toggleInMyBar(_bar[i]);
    } else {
      await ref
          .read(pantryIngredientRepositoryProvider)
          .toggleInMyPantry(_pantry[i]);
    }
    if (mounted) setState(() {});
  }

  Future<void> _addToShopping(int i) async {
    final name = _name(i);
    final origin = _isBar ? 'bar' : 'pantry';
    int qty = 1;
    String? unit;
    if (!_isBar) {
      final p = _pantry[i];
      if (p.quantity != null) qty = p.quantity!.round().clamp(1, 9999);
      unit = p.unit;
    }
    final added = await ref.read(shoppingRepositoryProvider).ensureInShopping(
          name: name,
          origin: origin,
          quantity: qty,
          unit: unit,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added
          ? '$name added to shopping'
          : '$name is already on the shopping list'),
      duration: const Duration(seconds: 1),
    ));
    setState(() {});
  }

  Future<void> _markShoppingDone(int i) async {
    final name = _name(i);
    final n = await ref
        .read(shoppingRepositoryProvider)
        .markPendingBoughtByName(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(n > 0
          ? '$name marked bought'
          : 'No pending shopping line for $name'),
      duration: const Duration(seconds: 1),
    ));
    setState(() {});
  }

  Future<void> _delete(int i) async {
    if (_isBar) {
      if (_bar[i].isBundled) return;
      await ref
          .read(barIngredientRepositoryProvider)
          .deleteBarIngredient(_bar[i]);
    } else {
      if (_pantry[i].isBundled) return;
      await ref
          .read(pantryIngredientRepositoryProvider)
          .deletePantryIngredient(_pantry[i]);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save(int i) async {
    final price = double.tryParse(_priceCtrl.text.trim());
    final place =
        _placeCtrl.text.trim().isEmpty ? null : _placeCtrl.text.trim();
    final name = _nameCtrl.text.trim().isEmpty ? _name(i) : _nameCtrl.text.trim();
    if (_isBar) {
      final b = _bar[i];
      b
        ..name = name
        ..lastKnownPrice = price
        ..lastPurchasePlace = place;
      await ref.read(barIngredientRepositoryProvider).updateBarIngredient(b);
    } else {
      final p = _pantry[i];
      p
        ..name = name
        ..lastKnownPrice = price
        ..lastPurchasePlace = place
        ..unit = _notesCtrl.text.trim().isEmpty ? p.unit : _notesCtrl.text.trim();
      await ref
          .read(pantryIngredientRepositoryProvider)
          .updatePantryIngredient(p);
    }
    // Push price/place onto pending shopping lines so trip estimates update.
    await ref.read(shoppingRepositoryProvider).applyPricePlaceToPendingByName(
          name: name,
          price: price,
          place: place,
        );
    if (mounted) setState(() {});
  }

  Future<void> _changePhoto(int i) async {
    final picked = await pickPhotoFromCameraOrGallery(context);
    if (picked == null) return;
    if (_isBar) {
      _bar[i].localPhotoPath = picked.path;
      await ref
          .read(barIngredientRepositoryProvider)
          .updateBarIngredient(_bar[i]);
    } else {
      _pantry[i].localPhotoPath = picked.path;
      await ref
          .read(pantryIngredientRepositoryProvider)
          .updatePantryIngredient(_pantry[i]);
    }
    if (mounted) setState(() {});
  }

  ItemListState _listState(int i, Set<String> shoppingNames) {
    if (_inStock(i)) return ItemListState.stocked;
    if (shoppingNames.contains(_name(i).toLowerCase().trim())) {
      return ItemListState.shopping;
    }
    return ItemListState.defaults;
  }

  List<String> _history(int i) {
    if (_isBar) {
      final b = _bar[i];
      final lines = <String>[
        'Last modified: ${b.lastModified.toLocal()}',
        b.inMyBar ? 'In my bar' : 'Not in bar',
      ];
      for (final p in b.purchaseHistory.reversed.take(8)) {
        final when = p.purchaseDate?.toLocal().toString().split(' ').first ??
            'unknown date';
        lines.add(
            'Bought ${p.price ?? '?'} ${p.currency} @ ${p.place ?? '?'} ($when)');
      }
      return lines;
    }
    final p = _pantry[i];
    final lines = <String>[
      'Last modified: ${p.lastModified.toLocal()}',
      p.inMyPantry ? 'In my pantry' : 'Not in pantry',
    ];
    for (final rec in p.purchaseHistory.reversed.take(8)) {
      final when = rec.purchaseDate?.toLocal().toString().split(' ').first ??
          'unknown date';
      lines.add(
          'Bought ${rec.price ?? '?'} ${rec.currency} @ ${rec.place ?? '?'} ($when)');
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shoppingNames =
        ref.watch(shoppingItemNamesProvider).asData?.value ?? {};
    if (_count == 0) {
      return const Scaffold(body: Center(child: Text('No ingredients')));
    }

    return ItemDetailShell(
      itemCount: _count,
      initialIndex: widget.initialIndex.clamp(0, _count - 1),
      titleForIndex: _name,
      subtitleForIndex: (i) =>
          '${_isBar ? 'My Bar' : 'My Pantry'} · ${i + 1} of $_count',
      stateColorForIndex: (i) =>
          SisuColors.itemStateColors(isDark, _listState(i, shoppingNames)).bg,
      historyForIndex: _history,
      imageBuilder: (context, i) {
        final path = _photo(i);
        if (path != null && path.isNotEmpty && File(path).existsSync()) {
          return Image.file(File(path), fit: BoxFit.cover);
        }
        return Container(
          color: SisuColors.getListSurface(isDark),
          alignment: Alignment.center,
          child: Icon(
            _isBar ? Icons.liquor : Icons.kitchen,
            size: 56,
            color: SisuColors.getTextSecondaryColor(isDark),
          ),
        );
      },
      onChangePhoto: (i) => () => _changePhoto(i),
      onSaveEdit: _save,
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeaderWidget(
                  title: _isBar ? 'Bar options' : 'Pantry options'),
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
        final state = _listState(index, shoppingNames);
        final c = SisuColors.itemStateColors(isDark, state);
        if (isEditing) {
          return SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Last price')),
                TextField(
                    controller: _placeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Purchase place')),
                if (!_isBar)
                  TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Unit')),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_name(index),
                  style: TextStyle(
                      color: c.title,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                _inStock(index)
                    ? (_isBar ? 'In my bar' : 'In my pantry')
                    : shoppingNames
                            .contains(_name(index).toLowerCase().trim())
                        ? 'On shopping list'
                        : (_isBar ? 'Not in bar' : 'Not in pantry'),
                style: TextStyle(color: c.desc),
              ),
              if (_isBar) ...[
                if (_bar[index].category.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Category: ${_bar[index].category}',
                      style: TextStyle(color: c.desc)),
                ],
                if (_bar[index].flavorProfiles.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(_bar[index].flavorProfiles.join(' · '),
                      style: TextStyle(color: c.desc)),
                ],
                if (_bar[index].lastKnownPrice != null) ...[
                  const SizedBox(height: 8),
                  Text(
                      'Last price: \$${_bar[index].lastKnownPrice!.toStringAsFixed(2)}'
                      '${_bar[index].lastKnownPriceUnit != null ? ' / ${_bar[index].lastKnownPriceUnit}' : ''}',
                      style: TextStyle(color: c.desc)),
                ],
                if (_bar[index].lastPurchasePlace != null &&
                    _bar[index].lastPurchasePlace!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Location: ${_bar[index].lastPurchasePlace}',
                      style: TextStyle(color: c.desc)),
                ],
                const SizedBox(height: 16),
                Text('Used in cocktails',
                    style: TextStyle(
                        color: c.title, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final cocktailsAsync = ref.watch(
                        cocktailRecipesForIngredientProvider(
                            _bar[index].name));
                    return cocktailsAsync.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return Text('Not used in any cocktail',
                              style: TextStyle(color: c.desc));
                        }
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final recipe in list)
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                label: Text(recipe.name,
                                    style: const TextStyle(fontSize: 12)),
                                onPressed: () => context.push(
                                  AppRoutes.cocktailRecipe,
                                  extra: recipe,
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => Text('Loading…',
                          style: TextStyle(color: c.desc)),
                      error: (_, _) => const SizedBox.shrink(),
                    );
                  },
                ),
              ] else ...[
                if (_pantry[index].quantity != null) ...[
                  const SizedBox(height: 8),
                  Text(
                      'Qty: ${_pantry[index].quantity}${_pantry[index].unit != null ? ' ${_pantry[index].unit}' : ''}',
                      style: TextStyle(color: c.desc)),
                ],
                if (_pantry[index].lastKnownPrice != null) ...[
                  const SizedBox(height: 8),
                  Text(
                      'Last price: \$${_pantry[index].lastKnownPrice!.toStringAsFixed(2)}',
                      style: TextStyle(color: c.desc)),
                ],
                if (_pantry[index].lastPurchasePlace != null &&
                    _pantry[index].lastPurchasePlace!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Location: ${_pantry[index].lastPurchasePlace}',
                      style: TextStyle(color: c.desc)),
                ],
                if (_pantry[index].allergenTags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Allergens: ${_pantry[index].allergenTags.join(', ')}',
                      style: TextStyle(color: c.desc)),
                ],
                const SizedBox(height: 16),
                Text('Used in menus',
                    style: TextStyle(
                        color: c.title, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final menusAsync = ref.watch(
                        menuRecipesForIngredientProvider(
                            _pantry[index].name));
                    return menusAsync.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return Text('Not used in any menu',
                              style: TextStyle(color: c.desc));
                        }
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final recipe in list)
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                label: Text(recipe.name,
                                    style: const TextStyle(fontSize: 12)),
                                onPressed: () => context.push(
                                  AppRoutes.chefRecipe,
                                  extra: recipe,
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => Text('Loading…',
                          style: TextStyle(color: c.desc)),
                      error: (_, _) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
      actionsForIndex:
          (context, index, isEditing, startEdit, cancelEdit, saveEdit) {
        final bundled =
            _isBar ? _bar[index].isBundled : _pantry[index].isBundled;
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
        final onList = shoppingNames
            .contains(_name(index).toLowerCase().trim());
        return [
          DetailAction(
            icon: _inStock(index)
                ? Icons.remove_circle_outline
                : Icons.check_circle_outline,
            label: _inStock(index) ? 'Remove' : 'In stock',
            onPressed: () => _toggleStock(index),
            color: SisuColors.completedBackground,
          ),
          DetailAction(
            icon: onList ? Icons.done : Icons.add_shopping_cart,
            label: onList ? 'Done' : 'Shopping',
            onPressed: () =>
                onList ? _markShoppingDone(index) : _addToShopping(index),
            color: onList ? SisuColors.completedBackground : Colors.blue,
          ),
          if (!bundled)
            DetailAction(
              icon: Icons.delete_forever,
              label: 'Delete',
              color: Colors.red,
              onPressed: () => _delete(index),
            ),
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
