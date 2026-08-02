import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/provider_breadcrumbs.dart';

/// #147/#176 follow-up: the ring buffer that lets an exception-level error
/// log entry show recent Riverpod provider activity.
void main() {
  test('records add/update events with the provider name', () async {
    final breadcrumbs = ProviderBreadcrumbs();
    final controller = StreamController<int>();
    addTearDown(controller.close);
    final counter = StreamProvider<int>((ref) => controller.stream,
        name: 'counterProvider');

    final container = ProviderContainer(observers: [breadcrumbs]);
    addTearDown(container.dispose);

    final sub = container.listen(counter, (_, _) {});
    addTearDown(sub.close);
    controller.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(breadcrumbs.recent, isNotEmpty);
    expect(
        breadcrumbs.recent
            .any((e) => e.contains('add') && e.contains('counterProvider')),
        isTrue);
    expect(
        breadcrumbs.recent
            .any((e) => e.contains('update') && e.contains('counterProvider')),
        isTrue);
  });

  test('caps at maxEntries, dropping the oldest first', () {
    final breadcrumbs = ProviderBreadcrumbs(maxEntries: 3);
    final container = ProviderContainer(observers: [breadcrumbs]);
    addTearDown(container.dispose);

    for (var i = 0; i < 6; i++) {
      final p = Provider<int>((ref) => i, name: 'p$i');
      container.read(p);
    }

    expect(breadcrumbs.recent, hasLength(3));
    // The last 3 providers read (p3, p4, p5) should be present; the first
    // three (p0, p1, p2) should have been dropped.
    expect(breadcrumbs.recent.any((e) => e.contains('p0')), isFalse);
    expect(breadcrumbs.recent.any((e) => e.contains('p5')), isTrue);
  });
}
