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
const bool kBypassOnboardingForTesting = true;

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

  static const _pages = [_WelcomePage(), _FeaturesPage(), _ProPage(), _GetStartedPage()];

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

    return Scaffold(
      backgroundColor: SisuColors.getBackgroundColor(false),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isLast
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: _finish,
                        child: const Text('Skip'),
                      ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages,
              ),
            ),

            // Dots + navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dots
                  Row(
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? SisuColors.proOnline
                              : SisuColors.proOnline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started
                  FilledButton(
                    onPressed: isLast ? _finish : _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: SisuColors.proOnline,
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
    );
  }
}

// ── Individual pages ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) => _OnboardingPage(
        icon: Icons.directions_boat,
        iconColor: SisuColors.proOnline,
        title: 'Welcome to Sisu Mate',
        subtitle: 'Your offline-first boating companion',
        body:
            'Everything you need before and during a voyage — '
            'checklists, maintenance schedules, the captain\'s log, '
            'crew briefings, recipes, and more. '
            'All available offline, even in the middle of the ocean.',
      );
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) => _OnboardingPage(
        icon: Icons.checklist_rtl,
        iconColor: Colors.blue,
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
        iconColor: Colors.amber,
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
        iconColor: SisuColors.proOnline,
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
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: iconColor),
          const SizedBox(height: 32),
          Text(
            title,
            style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: tt.titleMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (body != null)
            Text(body!, style: tt.bodyMedium, textAlign: TextAlign.center),
          if (bullets != null)
            ...bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(b, style: tt.bodyMedium),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
