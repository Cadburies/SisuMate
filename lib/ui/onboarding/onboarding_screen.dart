import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_router.dart';
import '../../core/colors.dart';

const _kOnboardingSeenKey = 'onboarding_seen_v1';

/// TESTING BYPASS — when true, onboarding is skipped and the app goes straight
/// to Home. Only ever takes effect in debug builds (gated by [kDebugMode] at
/// the use site), so a release build always shows onboarding even if this is
/// left `true`. Tracked in outstanding.md (RM2).
const bool kBypassOnboardingForTesting = false;

/// Returns true if the user has already completed onboarding (or the testing
/// bypass is on, in debug builds only).
Future<bool> hasSeenOnboarding() async {
  if (kDebugMode && kBypassOnboardingForTesting) return true;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingSeenKey) ?? false;
}

Future<void> _markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingSeenKey, true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _WelcomePage(),
    _PitchPage(),
    _FeaturesPage(),
    _ProPage(),
    _GetStartedPage(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = SisuColors.getHomeTile(isDark);
    final onFill = SisuColors.getTextPrimaryColor(isDark);

    return Scaffold(
      backgroundColor: fill,
      body: DecoratedBox(
        key: const ValueKey('onboarding_gradient'),
        decoration: BoxDecoration(
          gradient: SisuColors.tonalBarGradient(fill),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isLast
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: _finish,
                          child: Text(
                            'Skip',
                            style: TextStyle(color: onFill),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: _pages,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _page == i ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _page == i
                                ? onFill
                                : onFill.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    FilledButton(
                      onPressed: isLast ? _finish : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: SisuColors.proOnline,
                        foregroundColor: SisuColors.darkTextPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                      ),
                      child: Text(isLast ? 'Get Started' : 'Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual pages ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) => _OnboardingPage(
        icon: Icons.directions_boat,
        iconColor: SisuColors.completedText,
        title: 'Welcome to Sisu Mate',
        subtitle: 'Your offline-first boating companion',
        body:
            'Everything you need before and during a voyage — '
            'checklists, maintenance schedules, the captain\'s log, '
            'crew briefings, recipes, and more. '
            'All available offline, even in the middle of the ocean.',
      );
}

/// First-run list pitch from `marketting/pitch.txt` (#347).
class _PitchPage extends StatelessWidget {
  const _PitchPage();

  static const _colours = <(ItemListState, String, String)>[
    (
      ItemListState.defaults,
      'Grey',
      'Still to do, or listed but not aboard. No alarm.',
    ),
    (ItemListState.stocked, 'Green', 'Done / aboard.'),
    (ItemListState.shopping, 'Blue', 'On the shopping list.'),
    (
      ItemListState.unavailable,
      'Red',
      'Missing for this recipe (Chef / Cocktails only). Alarm.',
    ),
    (ItemListState.hidden, 'Dark grey', 'Hidden on purpose.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final onFill = SisuColors.getTextPrimaryColor(isDark);
    final muted = onFill.withValues(alpha: 0.75);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.swipe, size: 80, color: SisuColors.completedText),
          const SizedBox(height: 24),
          Text(
            'Lists',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onFill,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Open a list and work the tiles. Colour is the status — no tick or cart icon.',
            style: tt.titleMedium?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'How to use',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: onFill,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _pitchLine(tt, onFill, 'Tap a tile to open, edit, save.'),
          _pitchLine(tt, onFill, 'Swipe left = done / in stock.'),
          _pitchLine(tt, onFill, 'Swipe right = hide, shopping, or delete.'),
          _pitchLine(tt, onFill, 'Hidden stays in the list until you unhide it.'),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Colours',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: onFill,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final row in _colours)
            _colourRow(isDark, tt, onFill, row.$1, row.$2, row.$3),
          const SizedBox(height: 12),
          Text(
            'Grey on pantry/bar means “not aboard.” Red only means “this dish or drink is blocked.” They are not two names for the same thing.',
            style: tt.bodyMedium?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _pitchLine(TextTheme tt, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('• $text', style: tt.bodyMedium?.copyWith(color: color)),
      ),
    );
  }

  Widget _colourRow(
    bool isDark,
    TextTheme tt,
    Color onFill,
    ItemListState state,
    String name,
    String meaning,
  ) {
    final c = SisuColors.itemStateColors(isDark, state);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: tt.bodyMedium?.copyWith(color: onFill),
                children: [
                  TextSpan(
                    text: '$name  ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: meaning),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) => _OnboardingPage(
        icon: Icons.checklist_rtl,
        iconColor: SisuColors.stateShoppingDesc,
        title: '13 Integrated Modules',
        subtitle: 'Everything in one place',
        body:
            'Checklists  •  Shopping  •  Captain\'s Log\n'
            'Maintenance  •  Safety Briefings  •  Documents\n'
            'Crew & Contacts  •  Inventory  •  Fuel & Water\n'
            'Chef  •  Cocktails  •  Games  •  Community\n\n'
            'Browse and view all content for free, on any device, with no internet required.',
      );
}

class _ProPage extends StatelessWidget {
  const _ProPage();

  @override
  Widget build(BuildContext context) => _OnboardingPage(
        icon: Icons.workspace_premium,
        iconColor: SisuColors.completedText,
        title: 'Unlock Sisu Pro',
        subtitle: 'For the serious offshore sailor',
        bullets: const [
          '✓  Mark items complete & track history',
          '✓  Manage multiple boats',
          '✓  Real-time sync across all your devices',
          '✓  Browse the community template library',
          '✓  No ads — ever',
        ],
      );
}

class _GetStartedPage extends StatelessWidget {
  const _GetStartedPage();

  @override
  Widget build(BuildContext context) => _OnboardingPage(
        icon: Icons.anchor,
        iconColor: SisuColors.completedText,
        title: 'Ready to cast off?',
        subtitle: 'Your bundled content is already loaded',
        body:
            'Yanmar service schedules, annual safety checks, '
            'safety briefings, galley recipes, cocktails, and more '
            'are waiting for you.\n\n'
            'You can upgrade to Pro any time from the menu.',
      );
}

// ── Shared layout ─────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? body;
  final List<String>? bullets;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.body,
    this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final onFill = SisuColors.getTextPrimaryColor(isDark);
    final muted = onFill.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: iconColor),
          const SizedBox(height: 32),
          Text(
            title,
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onFill,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: tt.titleMedium?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (body != null)
            Text(
              body!,
              style: tt.bodyMedium?.copyWith(color: onFill),
              textAlign: TextAlign.center,
            ),
          if (bullets != null)
            ...bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(b, style: tt.bodyMedium?.copyWith(color: onFill)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
