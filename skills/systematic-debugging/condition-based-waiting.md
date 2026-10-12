# Condition-based waiting (Flutter)

Adapted from obra/superpowers `condition-based-waiting` (MIT), rewritten for flutter_test.

A test that sleeps for a guessed duration passes on an idle machine and fails when the suite runs alongside other agents (#424). Wait for the **condition**, or control the clock.

| Situation | Do | Don't |
| --- | --- | --- |
| Pure logic with `Timer`/`Future.delayed` (game AI turns, debounce) | `fakeAsync((async) { ...; async.elapse(d); async.flushMicrotasks(); })`. The clock is fake, so it's deterministic. Example: `test/dudo_test.dart` | Real `await Future.delayed(...)` |
| Widget test with app timers | `await tester.pump(d)` for exact timed steps. Use `pumpAndSettle()` only when nothing repeats forever | `pumpAndSettle` with a periodic timer or animation (it hangs and times out) |
| Real I/O inside a widget test (Drift, file, isolate) | `await tester.runAsync(() => ...)`, then poll the condition (example: `test/feature_map/launch_test.dart`) | One `runAsync(() => Future.delayed(500ms))` and hope |
| Wait for state | Loop: pump, check the finder or provider value, stop when it holds; cap the iterations and fail with a message naming the condition | Read state once before the loop (stale) |

## Poll helper shape

```dart
Future<void> pumpUntil(WidgetTester t, bool Function() cond,
    {String what = 'condition', int maxPumps = 100}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (cond()) return;
    await t.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $what');
}
```

## When a fixed duration is right

Only when the behaviour itself is timed (an AI "thinking" delay, a debounce window). Wait for the triggering condition first, then elapse a duration derived from the constant in the code (not a guess). Add a comment naming that constant.

## Teardown

Any `Timer` still pending at test end fails the test ("A Timer is still pending"). Also, a callback firing after dispose caused #411, #414 and #417. Elapse or cancel timers before teardown, and guard callbacks with `ref.mounted` / `mounted`.
