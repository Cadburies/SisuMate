import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/feature_map.dart' as fm;
import '_reach.dart';

/// #354: every host-reachable UI feature's `reach` line is executed here, so a
/// renamed label or moved button turns the suite red before a device agent
/// trips over it. `scripts/fm.sh <id> --reach` runs one id via FM_ID.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const only = String.fromEnvironment('FM_ID');
  final features = fm.loadFeatures(Directory(fm.featureMapRoot)).where((f) =>
      f.isUx &&
      f.needs['platform'] != 'device' &&
      (only.isEmpty || f.id == only));
  for (final f in features) {
    testWidgets('reach ${f.id}', (tester) async {
      await reach(tester, f.id);
      await drain(tester); // game AI turns run on short timers
    });
  }
}
