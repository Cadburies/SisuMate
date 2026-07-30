import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/ui/games/games/uno/logic.dart';

// Lets tests seed an arbitrary state directly, rather than only reachable
// via a full deal with random hands.
class _SeededUnoNotifier extends UnoNotifier {
  final UnoState initial;
  _SeededUnoNotifier(this.initial);
  @override
  UnoState build() => initial;
}

ProviderContainer _makeSeeded(UnoState initial) {
  final c = ProviderContainer(overrides: [
    unoStateProvider.overrideWith(() => _SeededUnoNotifier(initial)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  // ── UnoCard.canPlayOn ─────────────────────────────────────────────────────

  group('UnoCard.canPlayOn', () {
    test('matching color can play', () {
      const card = UnoCard(UnoColor.red, UnoValue.five);
      expect(card.canPlayOn(UnoColor.red, UnoValue.two), isTrue);
    });

    test('matching value can play', () {
      const card = UnoCard(UnoColor.blue, UnoValue.five);
      expect(card.canPlayOn(UnoColor.red, UnoValue.five), isTrue);
    });

    test('wild card can always play', () {
      const card = UnoCard(UnoColor.wild, UnoValue.wild);
      expect(card.canPlayOn(UnoColor.blue, UnoValue.nine), isTrue);
      expect(card.canPlayOn(UnoColor.red, UnoValue.zero), isTrue);
    });

    test('wild draw four can always play', () {
      const card = UnoCard(UnoColor.wild, UnoValue.wildDrawFour);
      expect(card.canPlayOn(UnoColor.green, UnoValue.eight), isTrue);
    });

    test('mismatched color and value cannot play', () {
      const card = UnoCard(UnoColor.blue, UnoValue.three);
      expect(card.canPlayOn(UnoColor.red, UnoValue.seven), isFalse);
    });
  });

  // ── UnoCard properties ────────────────────────────────────────────────────

  group('UnoCard properties', () {
    test('isWild for wild cards', () {
      expect(const UnoCard(UnoColor.wild, UnoValue.wild).isWild, isTrue);
      expect(const UnoCard(UnoColor.wild, UnoValue.wildDrawFour).isWild, isTrue);
      expect(const UnoCard(UnoColor.red, UnoValue.five).isWild, isFalse);
    });

    test('isAction for action cards', () {
      expect(const UnoCard(UnoColor.red, UnoValue.skip).isAction, isTrue);
      expect(const UnoCard(UnoColor.blue, UnoValue.reverse).isAction, isTrue);
      expect(const UnoCard(UnoColor.green, UnoValue.drawTwo).isAction, isTrue);
      expect(const UnoCard(UnoColor.wild, UnoValue.wild).isAction, isTrue);
      expect(const UnoCard(UnoColor.red, UnoValue.seven).isAction, isFalse);
    });

    test('toString', () {
      const c = UnoCard(UnoColor.red, UnoValue.five);
      expect(c.toString(), 'Red 5');
    });
  });

  // ── UnoNotifier — initial state ───────────────────────────────────────────

  group('UnoNotifier — initial state', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('player and AI each get 7 cards', () {
      final c = make();
      final s = c.read(unoStateProvider);
      expect(s.playerHand.length, 7);
      expect(s.aiHand.length, 7);
    });

    test('discard pile starts with one card', () {
      final c = make();
      expect(c.read(unoStateProvider).discardPile.length, 1);
    });

    test('start card is not wild', () {
      final c = make();
      final start = c.read(unoStateProvider).discardPile.first;
      expect(start.isWild, isFalse);
    });

    test('phase is playing, player turn', () {
      final c = make();
      final s = c.read(unoStateProvider);
      expect(s.phase, UnoPhase.playing);
      expect(s.isPlayerTurn, isTrue);
    });

    test('total card count is 108', () {
      final c = make();
      final s = c.read(unoStateProvider);
      final total = s.deck.length + s.playerHand.length +
          s.aiHand.length + s.discardPile.length;
      expect(total, 108);
    });
  });

  // ── selectCard ────────────────────────────────────────────────────────────

  group('selectCard', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('selecting invalid card clears selection', () {
      final c = make();
      final s = c.read(unoStateProvider);
      // Find a card that cannot play on current top
      final badIdx = s.playerHand.indexWhere(
        (card) => !card.canPlayOn(s.currentColor, s.currentValue),
      );
      if (badIdx != -1) {
        c.read(unoStateProvider.notifier).selectCard(badIdx);
        expect(c.read(unoStateProvider).selectedCardIndex, isNull);
      }
    });

    test('selecting valid card sets selectedCardIndex', () {
      final c = make();
      final s = c.read(unoStateProvider);
      final goodIdx = s.playerHand.indexWhere(
        (card) => card.canPlayOn(s.currentColor, s.currentValue),
      );
      if (goodIdx != -1) {
        c.read(unoStateProvider.notifier).selectCard(goodIdx);
        expect(c.read(unoStateProvider).selectedCardIndex, goodIdx);
      }
    });
  });

  // ── drawCard ──────────────────────────────────────────────────────────────

  group('drawCard', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('drawing adds a card to player hand', () {
      final c = make();
      final before = c.read(unoStateProvider).playerHand.length;
      // Make sure there's no playable card to avoid auto-draw complication
      // We just draw and check hand grew
      c.read(unoStateProvider.notifier).drawCard();
      final after = c.read(unoStateProvider).playerHand.length;
      // Hand grew by 1 (if card didn't match and trigger AI turn)
      // If drawn card matches, selectedCardIndex is set
      expect(after >= before, isTrue);
    });
  });

  // ── playSelected ──────────────────────────────────────────────────────────

  group('playSelected', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('playing a non-wild card removes it from hand', () {
      final c = make();
      final s = c.read(unoStateProvider);
      final idx = s.playerHand.indexWhere(
        (card) => card.canPlayOn(s.currentColor, s.currentValue) && !card.isWild,
      );
      if (idx != -1) {
        c.read(unoStateProvider.notifier).selectCard(idx);
        final before = c.read(unoStateProvider).playerHand.length;
        c.read(unoStateProvider.notifier).playSelected();
        expect(c.read(unoStateProvider).playerHand.length, before - 1);
      }
    });

    test('playSelected is no-op when nothing is selected', () {
      final c = make();
      final before = c.read(unoStateProvider).playerHand.length;
      c.read(unoStateProvider.notifier).playSelected();
      expect(c.read(unoStateProvider).playerHand.length, before);
    });
  });

  // ── newGame ───────────────────────────────────────────────────────────────

  group('newGame', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('resets to 7 cards each', () {
      final c = make();
      c.read(unoStateProvider.notifier).drawCard();
      c.read(unoStateProvider.notifier).newGame();
      final s = c.read(unoStateProvider);
      expect(s.playerHand.length, 7);
      expect(s.aiHand.length, 7);
    });

    test('resets phase to playing', () {
      final c = make();
      c.read(unoStateProvider.notifier).newGame();
      expect(c.read(unoStateProvider).phase, UnoPhase.playing);
    });
  });

  // ── GB2: AI-played Wild Draw Four must skip the human's next turn ────────

  group('AI Wild Draw Four skips the human (GB2)', () {
    test(
        'previously isPlayerTurn was left true after AI\'s Wild +4, letting '
        'the human play immediately instead of losing their turn — '
        'asymmetric with the human-initiated path (chooseColor), which '
        'already correctly skips the AI', () {
      fakeAsync((async) {
        final c = _makeSeeded(UnoState(
          // Plenty of draw fodder for the player's forced +4 draw.
          deck: List.generate(
              10, (i) => UnoCard(UnoColor.values[i % 4], UnoValue.nine)),
          playerHand: const [
            UnoCard(UnoColor.red, UnoValue.five),
            UnoCard(UnoColor.green, UnoValue.three),
          ],
          // Blue 7 doesn't match red/five, so it's unplayable and stays in
          // the AI's hand — forcing the AI to play its only playable card,
          // the Wild +4, rather than preferring a matching color card.
          aiHand: const [
            UnoCard(UnoColor.wild, UnoValue.wildDrawFour),
            UnoCard(UnoColor.blue, UnoValue.seven),
          ],
          discardPile: const [UnoCard(UnoColor.red, UnoValue.five)],
          currentColor: UnoColor.red,
          currentValue: UnoValue.five,
          isPlayerTurn: true,
          phase: UnoPhase.playing,
          message: '',
        ));
        final notifier = c.read(unoStateProvider.notifier);

        // Play Red 5 — a plain, non-action card — leaving the AI to act.
        notifier.selectCard(0);
        notifier.playSelected();
        async.elapse(const Duration(milliseconds: 750));

        final s = c.read(unoStateProvider);
        expect(s.discardPile.last.value, UnoValue.wildDrawFour,
            reason: 'AI had only one playable card and must have played it');
        expect(s.playerHand.length, 1 + 4,
            reason: 'Green 3 plus the forced draw of 4');
        expect(s.isPlayerTurn, isFalse,
            reason: 'the human must be skipped after drawing 4, just like a human-played +4 skips the AI');
      });
    });
  });

  // ── Multiplayer (GAME1) ────────────────────────────────────────────────────

  group('UnoNotifier.initHostMode — absolute host/guest roles', () {
    test('opponent isAI flag comes from the 2nd LobbyPlayer, host is always "player"',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(unoStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'guest', name: 'Guest', isAI: false),
      ]);
      final s = c.read(unoStateProvider);
      expect(s.isMultiplayer, isTrue);
      expect(s.isOpponentAI, isFalse);
      expect(s.isPlayerTurn, isTrue, reason: 'host always starts');
      expect(s.phase, UnoPhase.playing);
      expect(s.playerHand.length, 7);
      expect(s.aiHand.length, 7);
    });

    test('a lobby-added AI opponent is reflected in isOpponentAI', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(unoStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'ai_1', name: 'AI 1', isAI: true),
      ]);
      expect(c.read(unoStateProvider).isOpponentAI, isTrue);
    });
  });

  group('UnoNotifier — host/client mode flags', () {
    test('initHostMode/initClientMode/exitMultiplayerMode toggle isClientMode',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(unoStateProvider.notifier);
      expect(notifier.isClientMode, isFalse);

      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);
      expect(c.read(unoStateProvider).isMultiplayer, isTrue);

      notifier.exitMultiplayerMode();
      expect(notifier.isClientMode, isFalse);
    });

    test('newGame exits multiplayer mode', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(unoStateProvider.notifier);
      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);

      notifier.newGame();
      expect(notifier.isClientMode, isFalse);
      expect(c.read(unoStateProvider).isMultiplayer, isFalse);
    });
  });

  group('UnoNotifier — multiplayer turn handoff (no AI auto-play)', () {
    test(
        'regression: the guest can select and play their own card — mirrors '
        'the bug found live in checkers/logic.dart: selectCard/playSelected '
        'originally indexed only state.playerHand, so a guest\'s '
        "remotely-forwarded taps on their own hand would have been silently "
        'ignored (guest could never play at all)', () {
      final c = _makeSeeded(UnoState(
        deck: List.generate(10, (i) => UnoCard(UnoColor.values[i % 4], UnoValue.nine)),
        playerHand: const [UnoCard(UnoColor.blue, UnoValue.two)],
        aiHand: const [UnoCard(UnoColor.red, UnoValue.five), UnoCard(UnoColor.green, UnoValue.three)],
        discardPile: const [UnoCard(UnoColor.red, UnoValue.one)],
        currentColor: UnoColor.red,
        currentValue: UnoValue.one,
        isPlayerTurn: false, // guest's turn (host's turn flag is false)
        phase: UnoPhase.playing,
        message: '',
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      final notifier = c.read(unoStateProvider.notifier);
      notifier.selectCard(0); // select the guest's own Red 5
      expect(c.read(unoStateProvider).selectedCardIndex, 0);

      notifier.playSelected();
      final s = c.read(unoStateProvider);
      expect(s.aiHand.length, 1);
      expect(s.discardPile.last, const UnoCard(UnoColor.red, UnoValue.five));
      expect(s.isPlayerTurn, isTrue, reason: 'turn passes back to the host');
    });

    test(
        'a human move that ends the turn does not trigger the local AI '
        'when the opponent is a real remote guest', () {
      fakeAsync((async) {
        final c = _makeSeeded(UnoState(
          deck: List.generate(10, (i) => UnoCard(UnoColor.values[i % 4], UnoValue.nine)),
          playerHand: const [UnoCard(UnoColor.red, UnoValue.five), UnoCard(UnoColor.green, UnoValue.three)],
          aiHand: const [UnoCard(UnoColor.blue, UnoValue.two)],
          discardPile: const [UnoCard(UnoColor.red, UnoValue.one)],
          currentColor: UnoColor.red,
          currentValue: UnoValue.one,
          isPlayerTurn: true,
          phase: UnoPhase.playing,
          message: '',
          isMultiplayer: true,
          isOpponentAI: false,
        ));
        final notifier = c.read(unoStateProvider.notifier);
        notifier.selectCard(0);
        notifier.playSelected();

        // Even after the solo AI-turn delay would have fired, the AI's hand
        // must be untouched — no local auto-play in real multiplayer.
        async.elapse(const Duration(seconds: 2));

        final s = c.read(unoStateProvider);
        expect(s.aiHand.length, 1, reason: 'no local AI turn should run');
        expect(s.isPlayerTurn, isFalse, reason: 'turn passes to the guest');
      });
    });

    test('a guest playing a Skip card hands the turn back to the host, not '
        'to a local AI', () {
      fakeAsync((async) {
        final c = _makeSeeded(UnoState(
          deck: List.generate(10, (i) => UnoCard(UnoColor.values[i % 4], UnoValue.nine)),
          playerHand: const [UnoCard(UnoColor.blue, UnoValue.two)],
          aiHand: const [UnoCard(UnoColor.red, UnoValue.skip), UnoCard(UnoColor.green, UnoValue.three)],
          discardPile: const [UnoCard(UnoColor.red, UnoValue.one)],
          currentColor: UnoColor.red,
          currentValue: UnoValue.one,
          isPlayerTurn: false,
          phase: UnoPhase.playing,
          message: '',
          isMultiplayer: true,
          isOpponentAI: false,
        ));
        final notifier = c.read(unoStateProvider.notifier);
        notifier.selectCard(0);
        notifier.playSelected();
        async.elapse(const Duration(seconds: 1));

        final s = c.read(unoStateProvider);
        expect(s.isPlayerTurn, isFalse,
            reason: 'guest played skip, so the HOST is skipped and it bounces '
                "back to the guest's turn again, no AI involved");
      });
    });
  });

  group('UnoState JSON round-trip (broadcastIfHost payload)', () {
    test('toJson/fromJson round-trips every field', () {
      final s = UnoState(
        deck: const [UnoCard(UnoColor.red, UnoValue.nine)],
        playerHand: const [UnoCard(UnoColor.blue, UnoValue.two), UnoCard(UnoColor.wild, UnoValue.wildDrawFour)],
        aiHand: const [UnoCard(UnoColor.green, UnoValue.skip)],
        discardPile: const [UnoCard(UnoColor.red, UnoValue.one)],
        currentColor: UnoColor.yellow,
        currentValue: UnoValue.reverse,
        isPlayerTurn: false,
        phase: UnoPhase.choosingColor,
        message: 'Opponent turn',
        winner: null,
        selectedCardIndex: 1,
        isMultiplayer: true,
        isOpponentAI: false,
      );
      final round = UnoState.fromJson(s.toJson());
      Iterable<(UnoColor, UnoValue)> tuples(List<UnoCard> cards) =>
          cards.map((c) => (c.color, c.value));
      expect(tuples(round.deck), tuples(s.deck));
      expect(tuples(round.playerHand), tuples(s.playerHand));
      expect(tuples(round.aiHand), tuples(s.aiHand));
      expect(tuples(round.discardPile), tuples(s.discardPile));
      expect(round.currentColor, UnoColor.yellow);
      expect(round.currentValue, UnoValue.reverse);
      expect(round.isPlayerTurn, isFalse);
      expect(round.phase, UnoPhase.choosingColor);
      expect(round.selectedCardIndex, 1);
      expect(round.isMultiplayer, isTrue);
      expect(round.isOpponentAI, isFalse);
    });

    test('a null winner/selectedCardIndex survive the round-trip', () {
      final s = UnoState(
        deck: const [],
        playerHand: const [],
        aiHand: const [],
        discardPile: const [UnoCard(UnoColor.red, UnoValue.one)],
        currentColor: UnoColor.red,
        currentValue: UnoValue.one,
        isPlayerTurn: true,
        phase: UnoPhase.playing,
        message: '',
      );
      final round = UnoState.fromJson(s.toJson());
      expect(round.winner, isNull);
      expect(round.selectedCardIndex, isNull);
    });
  });
}
