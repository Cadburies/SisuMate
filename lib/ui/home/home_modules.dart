import 'package:flutter/material.dart';

import '../../core/app_router.dart';

/// One home-grid module. Ids are stable prefs keys — rename the title freely,
/// never recycle an id for a different module.
class HomeModule {
  final String id;
  final String title;
  final IconData icon;
  final Color accent;
  final String route;

  const HomeModule({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    required this.route,
  });
}

/// Canonical home-tile catalog. Default order is the pre-reorder layout
/// (Shopping first, Games last). Source of truth for merge + the grid.
abstract final class HomeModules {
  static const catalog = <HomeModule>[
    HomeModule(
      id: 'shopping',
      title: 'Shopping',
      icon: Icons.shopping_cart,
      accent: Colors.green,
      route: AppRoutes.shopping,
    ),
    HomeModule(
      id: 'cocktails',
      title: 'Cocktails',
      icon: Icons.local_bar,
      accent: Colors.deepPurple,
      route: AppRoutes.cocktails,
    ),
    HomeModule(
      id: 'chef',
      title: 'Chef',
      icon: Icons.restaurant_menu,
      accent: Colors.amber,
      route: AppRoutes.chef,
    ),
    HomeModule(
      id: 'safety',
      title: 'Safety',
      icon: Icons.health_and_safety,
      accent: Colors.red,
      route: AppRoutes.safety,
    ),
    HomeModule(
      id: 'checklists',
      title: 'Checklists',
      icon: Icons.checklist,
      accent: Colors.blue,
      route: AppRoutes.checklists,
    ),
    HomeModule(
      id: 'maintenance',
      title: 'Maintenance',
      icon: Icons.build,
      accent: Colors.orange,
      route: AppRoutes.maintenance,
    ),
    HomeModule(
      id: 'logbook',
      title: "Captain's Log",
      icon: Icons.book,
      accent: Colors.brown,
      route: AppRoutes.logbook,
    ),
    HomeModule(
      id: 'fuel',
      title: 'Fuel & Water',
      icon: Icons.local_gas_station,
      accent: Colors.deepOrange,
      route: AppRoutes.fuel,
    ),
    HomeModule(
      id: 'inventory',
      title: 'Inventory',
      icon: Icons.inventory,
      accent: Colors.teal,
      route: AppRoutes.inventory,
    ),
    HomeModule(
      id: 'crew',
      title: 'Crew & Contacts',
      icon: Icons.people,
      accent: Colors.purple,
      route: AppRoutes.crew,
    ),
    HomeModule(
      id: 'documents',
      title: 'Documents',
      icon: Icons.folder,
      accent: Colors.grey,
      route: AppRoutes.documents,
    ),
    HomeModule(
      id: 'community',
      title: 'Community',
      icon: Icons.people_outline,
      accent: Colors.cyan,
      route: AppRoutes.community,
    ),
    HomeModule(
      id: 'weather',
      title: 'Weather',
      icon: Icons.wb_cloudy,
      accent: Colors.lightBlue,
      route: AppRoutes.weather,
    ),
    HomeModule(
      id: 'polar',
      title: 'Polar',
      icon: Icons.radar,
      accent: Colors.cyanAccent,
      route: AppRoutes.polarChart,
    ),
    HomeModule(
      id: 'anchor',
      title: 'Anchor Alarm',
      icon: Icons.anchor,
      accent: Colors.blueGrey,
      route: AppRoutes.anchorAlarm,
    ),
    HomeModule(
      id: 'games',
      title: 'Games',
      icon: Icons.casino,
      accent: Colors.indigo,
      route: AppRoutes.games,
    ),
  ];

  static List<String> get defaultIds =>
      [for (final m in catalog) m.id];

  /// Apply a saved id list onto the current catalog.
  ///
  /// Unknown ids are dropped. Catalog ids missing from [saved] are inserted
  /// after the last catalog predecessor already present, so a newly shipped
  /// module lands next to its default neighbors instead of always after Games.
  static List<String> merge(List<String>? saved) {
    final known = {for (final m in catalog) m.id};
    final result = <String>[];
    if (saved != null) {
      for (final id in saved) {
        if (known.contains(id) && !result.contains(id)) result.add(id);
      }
    }
    for (var i = 0; i < catalog.length; i++) {
      final id = catalog[i].id;
      if (result.contains(id)) continue;
      var insertAt = 0;
      for (var j = 0; j < i; j++) {
        final pred = result.indexOf(catalog[j].id);
        if (pred >= 0) insertAt = pred + 1;
      }
      result.insert(insertAt, id);
    }
    return result;
  }

  /// Move [id] so it occupies [toIndex] in the pre-move list (ReorderableList
  /// convention: if moving forward, [toIndex] is the slot *after* removal).
  static List<String> moveIdTo(List<String> order, String id, int toIndex) {
    final from = order.indexOf(id);
    if (from < 0) return order;
    var dest = toIndex;
    if (dest < 0) dest = 0;
    if (dest > order.length) dest = order.length;
    if (from == dest || from + 1 == dest) return order;
    final list = List<String>.from(order);
    final item = list.removeAt(from);
    if (dest > from) dest -= 1;
    list.insert(dest.clamp(0, list.length), item);
    return list;
  }

  static List<HomeModule> resolve(List<String> ids) {
    final byId = {for (final m in catalog) m.id: m};
    final out = <HomeModule>[
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    if (out.length == catalog.length) return out;
    return [
      for (final id in merge(ids))
        if (byId[id] != null) byId[id]!,
    ];
  }
}
