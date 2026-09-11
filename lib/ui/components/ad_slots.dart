import 'dart:math';

/// Ad-slot placement for inline native ads ("tile ads") in module lists.
///
/// User policy (2026-08-01, supersedes prd.md §9.2 "every 8th item"):
/// at most [maxAds] native ads per list, placed at random positions **near
/// the beginning** of the list (the first [window] items), never adjacent
/// to another ad, and never at index 0 or 1 (the first tile must always be
/// real content so the list doesn't open on an ad).
///
/// Pure + deterministic under a seeded [random] for tests.
List<int> pickNativeAdSlots({
  required int itemCount,
  int maxAds = 4,
  int window = 16,
  int spacing = 2,
  Random? random,
}) {
  // Eligible positions: 2 .. min(itemCount, window) - 1 inclusive.
  final hi = min(itemCount, window);
  if (hi <= 2) return const [];

  final rnd = random ?? Random();
  final slots = <int>[];
  // Rejection-sample; the window is tiny so this always terminates quickly.
  var guard = 0;
  while (slots.length < maxAds && guard < 200) {
    guard++;
    final candidate = 2 + rnd.nextInt(hi - 2);
    final clashes = slots.any((s) => (s - candidate).abs() < spacing);
    if (!clashes) slots.add(candidate);
  }
  slots.sort();
  return slots;
}

/// True when the list position [index] holds an ad rather than content
/// (i.e. [index] is in [slots]).
bool isNativeAdSlot(int index, List<int> slots) => slots.contains(index);

/// Maps a list position to its content index: positions before the first ad
/// map 1:1; every ad slot shifts subsequent content by one.
int nativeAdContentIndex(int index, List<int> slots) {
  var shift = 0;
  for (final s in slots) {
    if (index > s) shift++;
  }
  return index - shift;
}

/// Memoizes ad slots per item count so list rebuilds (setState, scroll,
/// data refresh) don't reshuffle ad positions under the user. Slots are
/// re-rolled when the item count changes or the owning screen is recreated
/// (fresh app open → fresh random positions, per policy).
class NativeAdSlotCache {
  List<int> _slots = const [];
  int _forCount = -1;

  List<int> call(int itemCount) {
    if (_forCount != itemCount) {
      _slots = pickNativeAdSlots(itemCount: itemCount);
      _forCount = itemCount;
    }
    return _slots;
  }

  /// #311 — Pro (and tester grant, which is `isPro`) must not reserve
  /// list/grid cells for ads. When [showAds] is false, return no slots so
  /// [childCount] stays equal to content size (a shrunk [NativeAdWidget]
  /// inside a fixed-aspect [SliverGrid] still leaves empty holes).
  List<int> forList(int itemCount, {required bool showAds}) {
    if (!showAds) return const [];
    return call(itemCount);
  }
}
