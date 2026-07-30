import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../ui/startup/startup_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/shopping/shopping_screen.dart';
import '../ui/cocktails/cocktails_screen.dart';
import '../ui/chef/chef_screen.dart';
import '../ui/safety/safety_screen.dart';
import '../ui/safety/safety_briefing_screen.dart';
import '../ui/checklists/checklist_screen.dart';
import '../ui/checklists/checklist_items_screen.dart';
import '../ui/maintenance/maintenance_screen.dart';
import '../ui/maintenance/maintenance_items_screen.dart';
import '../ui/logbook/logbook_screen.dart';
import '../ui/fuel/fuel_screen.dart';
import '../ui/inventory/inventory_screen.dart';
import '../ui/crew/crew_screen.dart';
import '../ui/documents/documents_screen.dart';
import '../ui/community/community_browser_screen.dart';
import '../ui/weather/weather_screen.dart';
import '../ui/weather/passage_planner_screen.dart';
import '../ui/games/games_screen.dart';
import '../ui/games/lobby/lobby_screen.dart';
import '../ui/games/components/game_help_screen.dart';
import '../ui/games/games/backgammon/screen.dart';
import '../ui/games/games/checkers/screen.dart';
import '../ui/games/games/cribbage/screen.dart';
import '../ui/games/games/dudo/screen.dart';
import '../ui/games/games/liars_dice/screen.dart';
import '../ui/games/games/poker/screen.dart';
import '../ui/games/games/solitaire/screen.dart';
import '../ui/games/games/uno/screen.dart';
import '../ui/games/games/yatzy/screen.dart';
import '../ui/account/account_setup_screen.dart';
import '../ui/account/join_boat_screen.dart';
import '../ui/admin/admin_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/settings/sync_status_screen.dart';
import '../ui/conflicts/conflict_resolution_screen.dart';
import '../ui/boats/boats_screen.dart';
import '../ui/chef/meal_planner_screen.dart';
import '../ui/chef/provision_planner_screen.dart';
import '../ui/chef/guest_profiles_screen.dart';
import '../ui/collections/collections_screen.dart';
import '../ui/components/ingredient_detail_screen.dart';
import '../ui/components/record_detail_screen.dart';
import '../ui/checklists/check_page_viewer.dart';

/// Named path constants. Use with [GoRouter] / [context.go] / [context.push].
abstract final class AppRoutes {
  static const startup = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';

  static const shopping = '/shopping';
  static const shoppingItemDetail = '/shopping/item';
  static const cocktails = '/cocktails';
  static const cocktailRecipe = '/cocktails/recipe';
  static const cocktailBatch = '/cocktails/recipe/batch';
  static const chef = '/chef';
  static const chefRecipe = '/chef/recipe';
  static const chefCookingMode = '/chef/recipe/cooking';
  static const mealPlanner = '/chef/meal-planner';
  static const mealPlanDetail = '/chef/meal-planner/detail';
  static const provisionPlanner = '/chef/meal-planner/detail/provision';
  static const guestProfiles = '/chef/guest-profiles';
  static const safety = '/safety';
  static const safetyItems = '/safety/items';
  static const safetyItemDetail = '/safety/items/detail';
  static const checklists = '/checklists';
  static const checklistItems = '/checklists/items';
  static const checklistItemDetail = '/checklists/items/detail';
  static const maintenance = '/maintenance';
  static const maintenanceItems = '/maintenance/items';
  static const maintenanceItemDetail = '/maintenance/items/detail';
  static const logbook = '/logbook';
  static const fuel = '/fuel';
  static const fuelDetail = '/fuel/detail';
  static const inventory = '/inventory';
  static const inventoryDetail = '/inventory/detail';
  static const crew = '/crew';
  static const crewDetail = '/crew/detail';
  static const documents = '/documents';
  static const documentsDetail = '/documents/detail';
  static const community = '/community';
  static const weather = '/weather';
  static const passage = '/weather/passage';
  static const games = '/games';
  static const gamePlay = '/games/play/:gameId';
  static const gameLobby = '/games/lobby/:gameId';
  static const gameHelp = '/games/help';
  static const settings = '/settings';
  static const boats = '/boats';
  static const accountSetup = '/account';
  static const joinBoat = '/join';
  static const admin = '/admin';
  static const syncStatus = '/settings/sync';
  static const conflicts = '/settings/conflicts';

  static const collections = '/collections';
  static const collectionDetail = '/collections/detail';
  static const recipeEditor = '/recipe-editor';
  static const barIngredientDetail = '/bar-ingredient-detail';
  static const pantryIngredientDetail = '/pantry-ingredient-detail';
  static const barcodeScanner = '/barcode-scanner';

  static String playGame(String gameId) => '/games/play/$gameId';
  static String lobbyGame(String gameId) => '/games/lobby/$gameId';
}

/// Game catalog for named routes (NAV1).
abstract final class GameCatalog {
  static const ids = <String>[
    'dudo',
    'liars_dice',
    'backgammon',
    'checkers',
    'cribbage',
    'poker',
    'solitaire',
    'uno',
    'yatzy',
  ];

  static const multiplayerReady = {
    'liars_dice',
    'dudo',
    'yatzy',
    'checkers',
    'backgammon',
    'cribbage',
    'uno',
    'poker',
  };

  /// Always single-player by design (not a multiplayer backlog item).
  static const soloOnlyByDesign = {'solitaire'};

  static String displayName(String gameId) => switch (gameId) {
        'dudo' => 'Dudo',
        'liars_dice' => "Liar's Dice",
        'backgammon' => 'Backgammon',
        'checkers' => 'Checkers',
        'cribbage' => 'Cribbage',
        'poker' => 'Poker',
        'solitaire' => 'Solitaire',
        'uno' => 'Uno',
        'yatzy' => 'Yatzy',
        _ => gameId,
      };

  static Widget buildScreen(String gameId) => switch (gameId) {
        'dudo' => const DudoScreen(),
        'liars_dice' => const LiarsDiceScreen(),
        'backgammon' => const BackgammonScreen(),
        'checkers' => const CheckersScreen(),
        'cribbage' => const CribbageScreen(),
        'poker' => const PokerScreen(),
        'solitaire' => const SolitaireScreen(),
        'uno' => const UnoScreen(),
        'yatzy' => const YatzyScreen(),
        _ => Scaffold(
            appBar: AppBar(title: const Text('Unknown game')),
            body: Center(child: Text('No game for id: $gameId')),
          ),
      };
}

T? _extraAs<T>(GoRouterState state) {
  final e = state.extra;
  if (e is T) return e;
  return null;
}

/// Shared builder for the checklist/safety/maintenance item-detail routes —
/// all three render [CheckPageViewer], only [fallback] differs.
Widget _checkPageViewerBuilder(GoRouterState state, String fallback) {
  final args = _extraAs<CheckPageViewerArgs>(state);
  if (args == null) {
    return _MissingExtraScreen(title: 'Item', fallback: fallback);
  }
  return CheckPageViewer(
    items: args.items,
    initialIndex: args.initialIndex,
    groupName: args.groupName,
  );
}

/// Shared builder for the fuel/crew/inventory/documents record-detail
/// routes — all four render [RecordDetailScreen], only [fallback] differs.
Widget _recordDetailBuilder(GoRouterState state, String fallback) {
  final args = _extraAs<RecordDetailArgs>(state);
  if (args == null) {
    return _MissingExtraScreen(title: 'Record', fallback: fallback);
  }
  return RecordDetailScreen(
    itemCount: args.itemCount,
    initialIndex: args.initialIndex,
    titleForIndex: args.titleForIndex,
    photoPathForIndex: args.photoPathForIndex,
    fieldsForIndex: args.fieldsForIndex,
    historyForIndex: args.historyForIndex,
    onSave: args.onSave,
    onDelete: args.onDelete,
    onPhotoChanged: args.onPhotoChanged,
    canEdit: args.canEdit,
  );
}

/// Application [GoRouter] — top-level modules + detail/game named routes (NAV1).
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.startup,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.startup,
        name: 'startup',
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.shopping,
        name: 'shopping',
        builder: (context, state) => const ShoppingScreen(),
        routes: [
          GoRoute(
            path: 'item',
            name: 'shoppingItemDetail',
            builder: (context, state) {
              final extra = _extraAs<({List<ShoppingItem> items, int initialIndex})>(state);
              if (extra == null) {
                return _MissingExtraScreen(
                  title: 'Shopping item',
                  fallback: AppRoutes.shopping,
                );
              }
              return ShoppingItemDetailScreen(
                items: extra.items,
                initialIndex: extra.initialIndex,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cocktails,
        name: 'cocktails',
        builder: (context, state) => const CocktailsScreen(),
        routes: [
          GoRoute(
            path: 'recipe',
            name: 'cocktailRecipe',
            builder: (context, state) {
              final recipe = _extraAs<Recipe>(state);
              if (recipe == null) {
                return _MissingExtraScreen(
                  title: 'Cocktail',
                  fallback: AppRoutes.cocktails,
                );
              }
              return CocktailRecipeDetailScreen(recipe: recipe);
            },
            routes: [
              GoRoute(
                path: 'batch',
                name: 'cocktailBatch',
                builder: (context, state) {
                  final recipe = _extraAs<Recipe>(state);
                  if (recipe == null) {
                    return _MissingExtraScreen(
                      title: 'Build a Round',
                      fallback: AppRoutes.cocktails,
                    );
                  }
                  return CocktailBatchScreen(recipe: recipe);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.chef,
        name: 'chef',
        builder: (context, state) => const ChefScreen(),
        routes: [
          GoRoute(
            path: 'recipe',
            name: 'chefRecipe',
            builder: (context, state) {
              final recipe = _extraAs<Recipe>(state);
              if (recipe == null) {
                return _MissingExtraScreen(
                  title: 'Recipe',
                  fallback: AppRoutes.chef,
                );
              }
              return ChefRecipeDetailScreen(recipe: recipe);
            },
            routes: [
              GoRoute(
                path: 'cooking',
                name: 'chefCookingMode',
                builder: (context, state) {
                  final extra = _extraAs<({String recipeName, String instructions})>(state);
                  if (extra == null) {
                    return _MissingExtraScreen(
                      title: 'Cooking Mode',
                      fallback: AppRoutes.chef,
                    );
                  }
                  return CookingModeScreen(
                    recipeName: extra.recipeName,
                    instructions: extra.instructions,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'meal-planner',
            name: 'mealPlanner',
            builder: (context, state) => const MealPlannerScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                name: 'mealPlanDetail',
                builder: (context, state) {
                  final plan = _extraAs<MealPlan>(state);
                  if (plan == null) {
                    return _MissingExtraScreen(
                      title: 'Meal Plan',
                      fallback: AppRoutes.mealPlanner,
                    );
                  }
                  return MealPlanDetailScreen(plan: plan);
                },
                routes: [
                  GoRoute(
                    path: 'provision',
                    name: 'provisionPlanner',
                    builder: (context, state) {
                      final plan = _extraAs<MealPlan>(state);
                      if (plan == null) {
                        return _MissingExtraScreen(
                          title: 'Provision List',
                          fallback: AppRoutes.mealPlanner,
                        );
                      }
                      return ProvisionPlannerScreen(plan: plan);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'guest-profiles',
            name: 'guestProfiles',
            builder: (context, state) => const GuestProfilesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.safety,
        name: 'safety',
        builder: (context, state) => const SafetyScreen(),
        routes: [
          GoRoute(
            path: 'items',
            name: 'safetyItems',
            builder: (context, state) {
              final group = _extraAs<ChecklistGroup>(state);
              if (group == null) {
                return _MissingExtraScreen(
                  title: 'Safety briefing',
                  fallback: AppRoutes.safety,
                );
              }
              return SafetyBriefingItemsScreen(group: group);
            },
            routes: [
              GoRoute(
                path: 'detail',
                name: 'safetyItemDetail',
                builder: (context, state) =>
                    _checkPageViewerBuilder(state, AppRoutes.safety),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.checklists,
        name: 'checklists',
        builder: (context, state) => const ChecklistScreen(),
        routes: [
          GoRoute(
            path: 'items',
            name: 'checklistItems',
            builder: (context, state) {
              final group = _extraAs<ChecklistGroup>(state);
              if (group == null) {
                return _MissingExtraScreen(
                  title: 'Checklist',
                  fallback: AppRoutes.checklists,
                );
              }
              return ChecklistItemsScreen(group: group);
            },
            routes: [
              GoRoute(
                path: 'detail',
                name: 'checklistItemDetail',
                builder: (context, state) =>
                    _checkPageViewerBuilder(state, AppRoutes.checklists),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.maintenance,
        name: 'maintenance',
        builder: (context, state) => const MaintenanceScreen(),
        routes: [
          GoRoute(
            path: 'items',
            name: 'maintenanceItems',
            builder: (context, state) {
              final group = _extraAs<ChecklistGroup>(state);
              if (group == null) {
                return _MissingExtraScreen(
                  title: 'Maintenance',
                  fallback: AppRoutes.maintenance,
                );
              }
              return MaintenanceItemsScreen(group: group);
            },
            routes: [
              GoRoute(
                path: 'detail',
                name: 'maintenanceItemDetail',
                builder: (context, state) =>
                    _checkPageViewerBuilder(state, AppRoutes.maintenance),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.logbook,
        name: 'logbook',
        builder: (context, state) => const LogbookScreen(),
      ),
      GoRoute(
        path: AppRoutes.fuel,
        name: 'fuel',
        builder: (context, state) => const FuelScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            name: 'fuelDetail',
            builder: (context, state) =>
                _recordDetailBuilder(state, AppRoutes.fuel),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.inventory,
        name: 'inventory',
        builder: (context, state) => const InventoryScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            name: 'inventoryDetail',
            builder: (context, state) =>
                _recordDetailBuilder(state, AppRoutes.inventory),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.crew,
        name: 'crew',
        builder: (context, state) => const CrewScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            name: 'crewDetail',
            builder: (context, state) =>
                _recordDetailBuilder(state, AppRoutes.crew),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.documents,
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            name: 'documentsDetail',
            builder: (context, state) =>
                _recordDetailBuilder(state, AppRoutes.documents),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.community,
        name: 'community',
        builder: (context, state) => const CommunityBrowserScreen(),
      ),
      GoRoute(
        path: AppRoutes.weather,
        name: 'weather',
        builder: (context, state) => const WeatherScreen(),
        routes: [
          GoRoute(
            path: 'passage',
            name: 'passage',
            builder: (context, state) {
              final extra = state.extra as Map<String, double?>?;
              return PassagePlannerScreen(
                initialLat: extra?['lat'],
                initialLon: extra?['lon'],
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.games,
        name: 'games',
        builder: (context, state) => const GamesScreen(),
        routes: [
          GoRoute(
            path: 'play/:gameId',
            name: 'gamePlay',
            builder: (context, state) {
              final id = state.pathParameters['gameId'] ?? '';
              return GameCatalog.buildScreen(id);
            },
          ),
          GoRoute(
            path: 'lobby/:gameId',
            name: 'gameLobby',
            builder: (context, state) {
              final id = state.pathParameters['gameId'] ?? '';
              return GameLobbyScreen(
                gameId: id,
                gameName: GameCatalog.displayName(id),
              );
            },
          ),
          GoRoute(
            path: 'help',
            name: 'gameHelp',
            builder: (context, state) {
              final data = _extraAs<GameHelpData>(state);
              if (data == null) {
                return _MissingExtraScreen(
                  title: 'Help',
                  fallback: AppRoutes.games,
                );
              }
              return GameHelpScreen(data);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'sync',
            name: 'syncStatus',
            builder: (context, state) => const SyncStatusScreen(),
          ),
          GoRoute(
            path: 'conflicts',
            name: 'conflicts',
            builder: (context, state) => const ConflictResolutionScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.boats,
        name: 'boats',
        builder: (context, state) => const BoatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountSetup,
        name: 'accountSetup',
        builder: (context, state) => const AccountSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinBoat,
        name: 'joinBoat',
        builder: (context, state) => const JoinBoatScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: AppRoutes.collections,
        name: 'collections',
        builder: (context, state) => const CollectionsScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            name: 'collectionDetail',
            builder: (context, state) {
              final collection = _extraAs<RecipeCollection>(state);
              if (collection == null) {
                return _MissingExtraScreen(
                  title: 'Collection',
                  fallback: AppRoutes.collections,
                );
              }
              return CollectionDetailScreen(collection: collection);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.recipeEditor,
        name: 'recipeEditor',
        builder: (context, state) {
          final args = _extraAs<AddEditRecipeArgs>(state);
          if (args == null) {
            return _MissingExtraScreen(
              title: 'Recipe Editor',
              fallback: AppRoutes.home,
            );
          }
          return AddEditRecipeDialog(
            recipeType: args.recipeType,
            existingRecipe: args.existingRecipe,
            existingIngredients: args.existingIngredients,
            prefillName: args.prefillName,
            prefillInstructions: args.prefillInstructions,
            onSave: args.onSave,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.barIngredientDetail,
        name: 'barIngredientDetail',
        builder: (context, state) {
          final extra = _extraAs<({List<BarIngredient> items, int initialIndex})>(state);
          if (extra == null) {
            return _MissingExtraScreen(
              title: 'Bar Ingredient',
              fallback: AppRoutes.cocktails,
            );
          }
          return IngredientDetailScreen.bar(
            items: extra.items,
            initialIndex: extra.initialIndex,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.pantryIngredientDetail,
        name: 'pantryIngredientDetail',
        builder: (context, state) {
          final extra = _extraAs<({List<PantryIngredient> items, int initialIndex})>(state);
          if (extra == null) {
            return _MissingExtraScreen(
              title: 'Pantry Ingredient',
              fallback: AppRoutes.chef,
            );
          }
          return IngredientDetailScreen.pantry(
            items: extra.items,
            initialIndex: extra.initialIndex,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.barcodeScanner,
        name: 'barcodeScanner',
        builder: (context, state) => const BarcodeScannerScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No route for ${state.uri}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MissingExtraScreen extends StatelessWidget {
  final String title;
  final String fallback;
  const _MissingExtraScreen({required this.title, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Missing data for $title. Open it from the list.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(fallback),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
