import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/colors.dart';
import 'package:sisu_mate/core/theme.dart';
import 'package:sisu_mate/ui/onboarding/onboarding_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #347: onboarding is the home-tile tonal bar (not light-grey under white
/// text) and teaches list colour/swipe from `marketting/pitch.txt`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockSharedPreferencesChannel();
  });

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createSisuMateTheme(brightness: brightness),
        home: const OnboardingScreen(),
      ),
    );
    await tester.pump();
  }

  testWidgets('dark onboarding is not light-grey; uses home-tile tonal bar',
      (tester) async {
    await pumpOnboarding(tester, brightness: Brightness.dark);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, isNot(SisuColors.lightBackground));
    expect(scaffold.backgroundColor, SisuColors.getHomeTile(true));

    final box = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('onboarding_gradient')),
    );
    final deco = box.decoration as BoxDecoration;
    expect(
      deco.gradient,
      SisuColors.tonalBarGradient(SisuColors.getHomeTile(true)),
    );
    expect(find.text('Welcome to Sisu Mate'), findsOneWidget);
  });

  testWidgets('light onboarding uses the light home-tile tonal bar',
      (tester) async {
    await pumpOnboarding(tester, brightness: Brightness.light);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, SisuColors.getHomeTile(false));
  });

  testWidgets('pitch page has swipe how-to and colour meanings',
      (tester) async {
    await pumpOnboarding(tester, brightness: Brightness.dark);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Lists'), findsOneWidget);
    expect(
      find.textContaining('Tap a tile to open, edit, save.'),
      findsOneWidget,
    );
    expect(find.textContaining('Swipe left = done / in stock.'), findsOneWidget);
    expect(
      find.textContaining('Swipe right = hide, shopping, or delete.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Hidden stays in the list until you unhide it.'),
      findsOneWidget,
    );
    expect(find.textContaining('Chef / Cocktails only'), findsOneWidget);
    expect(find.textContaining('Hidden on purpose.'), findsOneWidget);
    expect(
      find.textContaining('They are not two names for the same thing.'),
      findsOneWidget,
    );
  });
}
