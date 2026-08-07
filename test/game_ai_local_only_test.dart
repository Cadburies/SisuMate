import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/game_ai/game_ai_difficulty.dart';
import 'package:sisu_mate/services/game_ai/game_ai_persona.dart';

/// #299 — games AI stays fully local (no LlmClient).
void main() {
  test('game_ai package sources never import llm_client_service', () {
    final dir = Directory('lib/services/game_ai');
    expect(dir.existsSync(), isTrue);
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      expect(src.contains('llm_client'), isFalse, reason: f.path);
      expect(src.contains('LlmClient'), isFalse, reason: f.path);
    }
  });

  test('seat presets cover night-watch casual and competitive', () {
    expect(GameAiSeatPreset.all, hasLength(greaterThanOrEqualTo(2)));
    final casual = GameAiSeatPreset.nightWatchCasual;
    expect(casual.difficulty, GameAiDifficulty.easy);
    expect(casual.persona, GameAiPersona.chaos);
    final comp = GameAiSeatPreset.competitive;
    expect(comp.difficulty, GameAiDifficulty.hard);
    expect(comp.persona, GameAiPersona.tight);
  });
}
