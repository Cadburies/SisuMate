import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/image_service.dart';

void main() {
  late Directory tempRoot;
  late ImageService service;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('sisu_img_');
    service = ImageService();
    service.debugDocumentsOverride = tempRoot;
  });

  tearDown(() async {
    service.debugDocumentsOverride = null;
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('ImageService (IMG1)', () {
    test('persistPickedPath copies a temp file into user_images', () async {
      final src = File('${tempRoot.path}/cache_pick.jpg');
      await src.writeAsBytes(List<int>.filled(32, 7));

      final durable =
          await service.persistPickedPath(src.path, prefix: 'cocktail');
      expect(durable, isNot(src.path));
      expect(durable, contains('${tempRoot.path}/user_images/'));
      expect(durable, contains('cocktail_'));
      expect(File(durable).existsSync(), isTrue);
      expect(await File(durable).length(), 32);
    });

    test('persistPickedPath is idempotent for already-persisted paths',
        () async {
      final src = File('${tempRoot.path}/cache_pick.jpg');
      await src.writeAsBytes([1, 2, 3]);
      final first = await service.persistPickedPath(src.path, prefix: 'doc');
      final second = await service.persistPickedPath(first, prefix: 'doc');
      expect(second, first);
    });

    test('saveUserImage returns null when source missing', () async {
      final missing = File('${tempRoot.path}/nope.jpg');
      expect(await service.saveUserImage(missing, 'x'), isNull);
    });

    test('cleanupOrphanedImages deletes unreferenced files', () async {
      final src = File('${tempRoot.path}/a.jpg');
      await src.writeAsBytes([9]);
      final kept = await service.persistPickedPath(src.path, prefix: 'keep');
      final orphan =
          await service.persistPickedPath(src.path, prefix: 'orphan');
      final deleted = await service.cleanupOrphanedImages([kept]);
      expect(deleted, 1);
      expect(File(kept).existsSync(), isTrue);
      expect(File(orphan).existsSync(), isFalse);
    });
  });
}
