import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home.md` and `home/*`
/// shell features. Test names are feature ids (`scripts/fm.sh <id>`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home', (tester) async {
    await reach(tester, 'home');
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
  });
}
