/// GAI5: offline bot *style* for multiplayer AI seats — orthogonal to
/// [GameAiDifficulty] (skill). Same skill, different risk appetite.
enum GameAiPersona {
  /// Default EV-ish play (no extra bias).
  balanced,

  /// Bluffs more, challenges / dudo less — presses the table.
  aggressive,

  /// Rare bluffs, challenges / dudo early — rock-solid.
  tight,

  /// Noisy / unpredictable among near-best options.
  chaos;

  String get label => switch (this) {
        GameAiPersona.balanced => 'Balanced',
        GameAiPersona.aggressive => 'Aggressive',
        GameAiPersona.tight => 'Tight',
        GameAiPersona.chaos => 'Chaos',
      };

  /// Short seat-name token used in lobby ("Bluffer (Hard)").
  String get seatName => switch (this) {
        GameAiPersona.balanced => 'Bot',
        GameAiPersona.aggressive => 'Bluffer',
        GameAiPersona.tight => 'Rock',
        GameAiPersona.chaos => 'Wildcard',
      };

  static GameAiPersona fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'aggressive':
        return GameAiPersona.aggressive;
      case 'tight':
        return GameAiPersona.tight;
      case 'chaos':
        return GameAiPersona.chaos;
      default:
        return GameAiPersona.balanced;
    }
  }

  String get wire => name;

  GameAiPersona get next => switch (this) {
        GameAiPersona.balanced => GameAiPersona.aggressive,
        GameAiPersona.aggressive => GameAiPersona.tight,
        GameAiPersona.tight => GameAiPersona.chaos,
        GameAiPersona.chaos => GameAiPersona.balanced,
      };

  // ── Threshold biases (multipliers / additives applied on top of difficulty) ─

  /// Extra weight for bidding above expected count (Dudo) / pressing bluffs.
  double get bluffBoost => switch (this) {
        GameAiPersona.balanced => 0.0,
        GameAiPersona.aggressive => 1.4,
        GameAiPersona.tight => -0.7,
        GameAiPersona.chaos => 0.4,
      };

  /// Multiplier on long-shot / overbid penalties (tight = harsher).
  double get longShotMul => switch (this) {
        GameAiPersona.balanced => 1.0,
        GameAiPersona.aggressive => 0.55,
        GameAiPersona.tight => 1.55,
        GameAiPersona.chaos => 0.85,
      };

  /// Shift on Dudo survival floor / Liar's challenge bias (positive → call more).
  double get challengeBias => switch (this) {
        GameAiPersona.balanced => 0.0,
        GameAiPersona.aggressive => -0.10,
        GameAiPersona.tight => 0.12,
        GameAiPersona.chaos => -0.02,
      };

  /// Chance (0–1) to pick a random near-best legal action instead of the top.
  double get noiseChance => switch (this) {
        GameAiPersona.balanced => 0.0,
        GameAiPersona.aggressive => 0.08,
        GameAiPersona.tight => 0.05,
        GameAiPersona.chaos => 0.45,
      };
}
