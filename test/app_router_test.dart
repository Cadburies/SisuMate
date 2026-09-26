import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sisu_mate/core/app_router.dart';

void main() {
  group('AppRoutes (T3)', () {
    test('top-level module paths are unique and absolute', () {
      final paths = <String>[
        AppRoutes.startup,
        AppRoutes.onboarding,
        AppRoutes.home,
        AppRoutes.shopping,
        AppRoutes.cocktails,
        AppRoutes.chef,
        AppRoutes.safety,
        AppRoutes.checklists,
        AppRoutes.maintenance,
        AppRoutes.logbook,
        AppRoutes.fuel,
        AppRoutes.inventory,
        AppRoutes.crew,
        AppRoutes.documents,
        AppRoutes.community,
        AppRoutes.weather,
        AppRoutes.games,
        AppRoutes.settings,
        AppRoutes.boats,
      ];
      expect(paths.toSet().length, paths.length);
      for (final p in paths) {
        expect(p.startsWith('/'), isTrue, reason: p);
      }
    });

    test('nested settings/weather paths are under parents', () {
      expect(AppRoutes.syncStatus, startsWith('/settings'));
      expect(AppRoutes.conflicts, startsWith('/settings'));
      expect(AppRoutes.passage, startsWith('/weather'));
      // #232.
      expect(AppRoutes.departureWindow, startsWith('/weather'));
    });

    test('detail and game paths are nested under modules (NAV1)', () {
      expect(AppRoutes.checklistItems, startsWith('/checklists'));
      expect(AppRoutes.maintenanceItems, startsWith('/maintenance'));
      expect(AppRoutes.safetyItems, startsWith('/safety'));
      expect(AppRoutes.cocktailRecipe, startsWith('/cocktails'));
      expect(AppRoutes.chefRecipe, startsWith('/chef'));
      expect(AppRoutes.playGame('liars_dice'), '/games/play/liars_dice');
      expect(AppRoutes.lobbyGame('liars_dice'), '/games/lobby/liars_dice');
      expect(GameCatalog.ids, contains('liars_dice'));
      expect(GameCatalog.multiplayerReady, contains('liars_dice'));
    });

    test('createAppRouter builds without throwing', () {
      final router = createAppRouter();
      expect(router.configuration.routes, isNotEmpty);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.startup);
    });

    test('#354: createAppRouter honours initialLocation', () {
      final router = createAppRouter(initialLocation: AppRoutes.home);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    });

    test('TEST1: router knows named detail routes', () {
      final router = createAppRouter();
      // Smoke: configuration includes nested module paths (NAV1).
      final uriPaths = <String>{};
      void walk(List<RouteBase> routes, String parent) {
        for (final r in routes) {
          if (r is GoRoute) {
            final path = r.path.startsWith('/')
                ? r.path
                : '$parent/${r.path}'.replaceAll('//', '/');
            uriPaths.add(path);
            walk(r.routes, path);
          } else if (r is ShellRoute) {
            walk(r.routes, parent);
          }
        }
      }

      walk(router.configuration.routes, '');
      expect(uriPaths.any((p) => p.contains('checklists')), isTrue);
      expect(uriPaths.any((p) => p.contains('cocktails')), isTrue);
      expect(uriPaths.any((p) => p.contains('weather')), isTrue);
      expect(uriPaths.any((p) => p.contains('games')), isTrue);
    });
  });
}
