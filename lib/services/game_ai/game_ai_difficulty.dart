/// GAI1: offline bot skill for multiplayer AI seats and solo practice.
enum GameAiDifficulty {
  easy,
  normal,
  hard;

  String get label => switch (this) {
        GameAiDifficulty.easy => 'Easy',
        GameAiDifficulty.normal => 'Normal',
        GameAiDifficulty.hard => 'Hard',
      };

  String get shortLabel => switch (this) {
        GameAiDifficulty.easy => 'E',
        GameAiDifficulty.normal => 'N',
        GameAiDifficulty.hard => 'H',
      };

  static GameAiDifficulty fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'easy':
        return GameAiDifficulty.easy;
      case 'hard':
        return GameAiDifficulty.hard;
      default:
        return GameAiDifficulty.normal;
    }
  }

  String get wire => name;

  GameAiDifficulty get next => switch (this) {
        GameAiDifficulty.easy => GameAiDifficulty.normal,
        GameAiDifficulty.normal => GameAiDifficulty.hard,
        GameAiDifficulty.hard => GameAiDifficulty.easy,
      };
}
