import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/drawer/account*`.
/// Signing in, joining and the developer console talk to Supabase (device).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/drawer/account', (tester) async {
    await reach(tester, 'home/drawer/account');
    expect(find.text('Boat account'), findsOneWidget);
    expect(find.text('Join a boat'), findsOneWidget);
  });

  testWidgets('home/drawer/account/create', (tester) async {
    await reach(tester, 'home/drawer/account/create');
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('home/drawer/account/sign_in', (tester) async {
    await reach(tester, 'home/drawer/account/sign_in');
    expect(find.text('Sign in to your boat account'), findsOneWidget);
  });

  testWidgets('home/drawer/account/join_boat', (tester) async {
    await reach(tester, 'home/drawer/account/join_boat');
    expect(find.text('Enter the boat code'), findsOneWidget);
    expect(find.text('Join boat'), findsOneWidget);
  });

  testWidgets('home/drawer/account/boats', (tester) async {
    await reach(tester, 'home/drawer/account/boats');
    expect(find.text('My Boat'), findsOneWidget);
  });

  testWidgets('home/drawer/account/boats [free]', (tester) async {
    await reach(tester, 'home/drawer/settings', tier: 'free');
    expect(find.text('Manage Boats'), findsNothing);
    expect(find.text('Upgrade to Pro for multiple boats'), findsOneWidget);
  });

  testWidgets('home/drawer/account/add_boat', (tester) async {
    await reach(tester, 'home/drawer/account/add_boat');
    expect(find.text('Add New Boat'), findsOneWidget);
  });

  testWidgets('home/drawer/account/boat_options', (tester) async {
    await reach(tester, 'home/drawer/account/boat_options');
    expect(find.text('Edit'), findsOneWidget);
  });
}
