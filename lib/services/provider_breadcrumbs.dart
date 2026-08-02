import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ring buffer of recent Riverpod provider lifecycle events, so an
/// `exception`-level [ErrorLogService] entry can carry "what was the
/// provider graph doing right before this fired" — the piece a bare stack
/// trace can't show for framework-internal races (e.g. a StreamProvider
/// emission landing mid-build; see #147/#176). Register the observer once in
/// `main.dart`'s `ProviderScope(observers: [...])`; [ErrorLogService] reads
/// [recent] via a static callback, mirroring `routeHintProvider`.
///
/// Deliberately NOT persisted as part of the error's `message`/fingerprint —
/// breadcrumbs differ on every occurrence of the same bug (different
/// timestamps, possibly different providers depending on what the user was
/// doing), so folding them into the dedupe key would file a new GitHub issue
/// every single time instead of incrementing one fingerprint's occurrences.
final class ProviderBreadcrumbs extends ProviderObserver {
  ProviderBreadcrumbs({this.maxEntries = 20});

  final int maxEntries;
  final List<String> _events = [];

  List<String> get recent => List.unmodifiable(_events);

  void _record(String label, ProviderObserverContext context) {
    final ts = DateTime.now().toIso8601String().substring(11, 23); // HH:mm:ss.SSS
    _events.add('$ts $label ${context.provider.runtimeType} '
        '(${context.provider.name ?? context.provider.hashCode})');
    if (_events.length > maxEntries) _events.removeAt(0);
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    _record('add', context);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    _record('update', context);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    _record('dispose', context);
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    _record('FAIL(${error.runtimeType})', context);
  }
}
