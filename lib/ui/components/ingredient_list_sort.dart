/// Sort modes for My Bar / My Pantry ingredient lists (drawer options).
enum IngredientListSort {
  nameAsc,
  nameDesc,
  category,
  /// In stock → on shopping list → out of stock; then name A–Z within each.
  availability,
}

extension IngredientListSortLabels on IngredientListSort {
  String get label => switch (this) {
        IngredientListSort.nameAsc => 'Name A–Z',
        IngredientListSort.nameDesc => 'Name Z–A',
        IngredientListSort.category => 'Category',
        IngredientListSort.availability =>
          'Availability (stock → shopping → other)',
      };

  String get shortLabel => switch (this) {
        IngredientListSort.nameAsc => 'A–Z',
        IngredientListSort.nameDesc => 'Z–A',
        IngredientListSort.category => 'Category',
        IngredientListSort.availability => 'Availability',
      };
}

/// Shared sort + sticky-order helpers so toggling stock/shopping does not
/// reshuffle the visible list (user keeps their place). Full re-sort only when
/// [sortEpoch] changes (user picked a new mode in the drawer).
class IngredientListOrder {
  IngredientListSort sort;
  int sortEpoch;
  List<String>? _stickyIds;

  IngredientListOrder({
    this.sort = IngredientListSort.nameAsc,
    this.sortEpoch = 0,
  });

  void setSort(IngredientListSort next) {
    if (sort == next) return;
    sort = next;
    sortEpoch++;
    _stickyIds = null;
  }

  List<T> apply<T>({
    required List<T> items,
    required String Function(T) idOf,
    required String Function(T) nameOf,
    required String Function(T) categoryOf,
    required bool Function(T) inStockOf,
    required bool Function(T) inShoppingOf,
  }) {
    if (items.isEmpty) {
      _stickyIds = [];
      return items;
    }

    final byId = {for (final i in items) idOf(i): i};

    // Full sort when first load or user changed sort mode.
    if (_stickyIds == null) {
      final sorted = List<T>.from(items);
      _sortList(
        sorted,
        nameOf: nameOf,
        categoryOf: categoryOf,
        inStockOf: inStockOf,
        inShoppingOf: inShoppingOf,
      );
      _stickyIds = sorted.map(idOf).toList();
      return sorted;
    }

    // Sticky order: keep previous positions; drop missing; append new at end.
    final result = <T>[];
    for (final id in _stickyIds!) {
      final item = byId.remove(id);
      if (item != null) result.add(item);
    }
    if (byId.isNotEmpty) {
      final newcomers = byId.values.toList()
        ..sort((a, b) =>
            nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()));
      result.addAll(newcomers);
    }
    _stickyIds = result.map(idOf).toList();
    return result;
  }

  void _sortList<T>(
    List<T> list, {
    required String Function(T) nameOf,
    required String Function(T) categoryOf,
    required bool Function(T) inStockOf,
    required bool Function(T) inShoppingOf,
  }) {
    int availabilityRank(T i) {
      if (inStockOf(i)) return 0;
      if (inShoppingOf(i)) return 1;
      return 2;
    }

    list.sort((a, b) {
      switch (sort) {
        case IngredientListSort.nameAsc:
          return nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase());
        case IngredientListSort.nameDesc:
          return nameOf(b).toLowerCase().compareTo(nameOf(a).toLowerCase());
        case IngredientListSort.category:
          final c = categoryOf(a)
              .toLowerCase()
              .compareTo(categoryOf(b).toLowerCase());
          if (c != 0) return c;
          return nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase());
        case IngredientListSort.availability:
          final r = availabilityRank(a).compareTo(availabilityRank(b));
          if (r != 0) return r;
          return nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase());
      }
    });
  }
}
