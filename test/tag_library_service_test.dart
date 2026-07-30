import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/tag_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TagLibraryService', () {
    test('options include suggested tags', () async {
      final opts =
          await TagLibraryService.instance.options(TagKind.flavor);
      expect(opts, contains('citrus'));
      expect(opts, contains('tropical'));
    });

    test('remember adds novel tags and options surface them', () async {
      await TagLibraryService.instance.remember(TagKind.flavor, 'rummy spicy');
      final custom =
          await TagLibraryService.instance.customTags(TagKind.flavor);
      expect(custom.map((t) => t.toLowerCase()), contains('rummy spicy'));

      final opts =
          await TagLibraryService.instance.options(TagKind.flavor);
      expect(
        opts.any((t) => t.toLowerCase() == 'rummy spicy'),
        isTrue,
      );
    });

    test('remember ignores suggested duplicates case-insensitively', () async {
      await TagLibraryService.instance.remember(TagKind.flavor, 'Citrus');
      final custom =
          await TagLibraryService.instance.customTags(TagKind.flavor);
      expect(custom, isEmpty);
    });

    test('rememberAll skips blanks', () async {
      await TagLibraryService.instance
          .rememberAll(TagKind.cuisine, ['  ', 'My Style', '']);
      final custom =
          await TagLibraryService.instance.customTags(TagKind.cuisine);
      expect(custom, ['My Style']);
    });
  });
}
