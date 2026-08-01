import 'dart:math';

/// TEST28: reproducible offline bot RNG.
///
/// **Contract:** pure AI decision helpers accept an optional [Random]. Production
/// uses [create] (or omits the arg so the game’s module RNG is used). Unit tests
/// pass [seeded] and assert that **the same seed + same inputs ⇒ the same move**.
///
/// Do not drive game moves via cloud LLM (decision record: GitHub issue #12, GAI8).
abstract final class GameAiRng {
  /// Non-deterministic production RNG.
  static Random create() => Random();

  /// Fixed-seed RNG for tests and deterministic replay.
  static Random seeded(int seed) => Random(seed);

  /// Sample [n] ints in `0..maxExclusive-1` (handy for sequence equality checks).
  static List<int> sampleInts(Random rng, int n, int maxExclusive) =>
      List.generate(n, (_) => rng.nextInt(maxExclusive));
}
