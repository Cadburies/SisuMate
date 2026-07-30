import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';

Future<void> seedShoppingData(String defaultBoatSupabaseId) async {
  // ===================================================================
  // SHOPPING CATEGORIES
  // ===================================================================
  final shoppingCategories = <ShoppingCategory>[
    ShoppingCategory()
      ..supabaseId = 'cat-filters'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Filters'
      ..sortOrder = 0,
    ShoppingCategory()
      ..supabaseId = 'cat-impellers'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Impellers & Pump Kits'
      ..sortOrder = 1,
    ShoppingCategory()
      ..supabaseId = 'cat-belts'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Belts'
      ..sortOrder = 2,
    ShoppingCategory()
      ..supabaseId = 'cat-oils-fluids'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Oils & Fluids'
      ..sortOrder = 3,
    ShoppingCategory()
      ..supabaseId = 'cat-anodes'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Anodes / Zincs'
      ..sortOrder = 4,
    ShoppingCategory()
      ..supabaseId = 'cat-electrical'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Electrical & Batteries'
      ..sortOrder = 5,
    ShoppingCategory()
      ..supabaseId = 'cat-plumbing'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Plumbing & Sanitation'
      ..sortOrder = 6,
    ShoppingCategory()
      ..supabaseId = 'cat-safety'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Safety & Emergency'
      ..sortOrder = 7,
    ShoppingCategory()
      ..supabaseId = 'cat-engine'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Engine & Saildrive Spares'
      ..sortOrder = 8,
    ShoppingCategory()
      ..supabaseId = 'cat-rigging'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Rigging & Deck Hardware'
      ..sortOrder = 9,
    ShoppingCategory()
      ..supabaseId = 'cat-cleaning'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Cleaning & Maintenance'
      ..sortOrder = 10,
    ShoppingCategory()
      ..supabaseId = 'cat-misc'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Miscellaneous'
      ..sortOrder = 11,
  ];

  // ShoppingCategory moved to Drift (S1). insertOrIgnore keeps it idempotent.
  final db = AppDatabase.instance;
  await db.batch((b) {
    for (final c in shoppingCategories) {
      b.insert(
        db.shoppingCategories,
        ShoppingCategoriesCompanion.insert(
          supabaseId: Value(c.supabaseId),
          boatSupabaseId: Value(c.boatSupabaseId),
          name: Value(c.name),
          sortOrder: Value(c.sortOrder),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });

  // Categories only — no seeded items. A fresh install or factory reset
  // should give the user a genuinely empty shopping list, not example data
  // for one specific engine (Yanmar) under one specific category.
}
