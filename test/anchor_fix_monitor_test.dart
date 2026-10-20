import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/anchor_alarm_service.dart';

/// #436 (owner decision): an implausible position jump is not trusted until
/// a second fix confirms it, and an anchor watch with no trustworthy fix
/// for 3 minutes escalates to a "can't verify" alert.
void main() {
  late DateTime t;
  late AnchorFixMonitor m;

  // ~111 m per 0.001° latitude.
  const lat = 60.0, lon = 25.0;

  setUp(() {
    t = DateTime(2026, 10, 20, 12);
    m = AnchorFixMonitor(now: () => t);
  });

  void advance(Duration d) => t = t.add(d);

  test('first fix and small movement are trusted', () {
    expect(m.accept(lat, lon), isNotNull);
    advance(const Duration(seconds: 10));
    final p = m.accept(lat + 0.0002, lon); // ~22 m
    expect(p!.lat, lat + 0.0002);
  });

  test('a teleport is not trusted until a second fix confirms it', () {
    m.accept(lat, lon);
    advance(const Duration(seconds: 10));
    expect(m.accept(lat + 0.01, lon), isNull, reason: '~1.1 km in 10 s');
    advance(const Duration(seconds: 10));
    final p = m.accept(lat + 0.01001, lon);
    expect(p, isNotNull, reason: 'confirmed by a nearby second fix');
  });

  test('alternating spoofed positions are never trusted', () {
    m.accept(lat, lon);
    for (var i = 0; i < 6; i++) {
      advance(const Duration(seconds: 10));
      expect(m.accept(i.isEven ? lat + 0.01 : lat - 0.01, lon), isNull);
    }
  });

  test('a big move after a long outage is plausible', () {
    m.accept(lat, lon);
    advance(const Duration(minutes: 30));
    expect(m.accept(lat + 0.01, lon), isNotNull, reason: '1.1 km in 30 min');
  });

  test('no fix: nothing to trust', () {
    expect(m.accept(null, null), isNull);
    expect(m.accept(lat, null), isNull);
  });

  group('cantVerify', () {
    test('never while the watch is off', () {
      advance(const Duration(hours: 1));
      expect(m.cantVerify(watchActive: false), isFalse);
    });

    test('3 minutes into a watch without a trusted fix', () {
      expect(m.cantVerify(watchActive: true), isFalse);
      advance(const Duration(minutes: 2, seconds: 59));
      expect(m.cantVerify(watchActive: true), isFalse);
      advance(const Duration(seconds: 1));
      expect(m.cantVerify(watchActive: true), isTrue);
    });

    test('a trusted fix resets the clock; implausible ones do not', () {
      m.cantVerify(watchActive: true);
      m.accept(lat, lon);
      advance(const Duration(minutes: 2));
      m.accept(lat + 0.01, lon); // implausible, ignored
      advance(const Duration(minutes: 1));
      expect(m.cantVerify(watchActive: true), isTrue);
      m.accept(lat + 0.00001, lon);
      expect(m.cantVerify(watchActive: true), isFalse);
    });

    test('turning the watch off and on restarts the clock', () {
      m.cantVerify(watchActive: true);
      advance(const Duration(minutes: 5));
      expect(m.cantVerify(watchActive: true), isTrue);
      m.cantVerify(watchActive: false);
      expect(m.cantVerify(watchActive: true), isFalse);
    });
  });
}
