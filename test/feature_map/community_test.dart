import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/community*`. The
/// library content itself comes from Supabase (device / online).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/community', (tester) async {
    await reach(tester, 'home/community');
    expect(find.text('Community Library'), findsOneWidget);
    expect(find.text('Most Downloaded'), findsOneWidget);
  });

  testWidgets('home/community [free]', (tester) async {
    await reach(tester, 'home/community', tier: 'free');
    expect(find.textContaining('Community Library is Pro only'), findsOneWidget);
  });

  testWidgets('home/community/share_list', (tester) async {
    await reach(tester, 'home/community/share_list');
    expect(find.text('Choose a list to share'), findsOneWidget);
  });

  testWidgets('home/community/make_model', (tester) async {
    await reach(tester, 'home/community/make_model');
    expect(find.text('Volvo Penta'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('home/community/sort', (tester) async {
    await reach(tester, 'home/community/sort');
    expect(find.text('Recent'), findsOneWidget);
  });
}
