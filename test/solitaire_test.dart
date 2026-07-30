import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisu_mate/ui/games/games/solitaire/logic.dart';

ProviderContainer make() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

// Lets tests seed an arbitrary state directly, rather than only reachable
// via a full deal with random cards.
class _SeededSolitaireNotifier extends SolitaireNotifier {
  final SolitaireState initial;
  _SeededSolitaireNotifier(this.initial);
  @override
  SolitaireState build() => initial;
}

ProviderContainer _makeSeeded(SolitaireState initial) {
  final c = ProviderContainer(overrides: [
    solitaireProvider.overrideWith(() => _SeededSolitaireNotifier(initial)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  // ── Card helpers ──────────────────────────────────────────────────────────

  group('card helpers', () {
    test('suitOf returns 0-3', () {
      expect(suitOf(0), 0);   // first club
      expect(suitOf(13), 1);  // first diamond
      expect(suitOf(26), 2);  // first heart
      expect(suitOf(39), 3);  // first spade
    });

    test('rankOf returns 0-12', () {
      expect(rankOf(0), 0);   // Ace of clubs
      expect(rankOf(12), 12); // King of clubs
      expect(rankOf(13), 0);  // Ace of diamonds
    });

    test('isRed: diamonds (suit=1) and hearts (suit=2) are red', () {
      expect(isRed(13), isTrue);  // Ace of diamonds
      expect(isRed(26), isTrue);  // Ace of hearts
      expect(isRed(0), isFalse);  // Ace of clubs
      expect(isRed(39), isFalse); // Ace of spades
    });

    test('cardLabel formats correctly', () {
      expect(cardLabel(0), 'A♣');
      expect(cardLabel(12), 'K♣');
      expect(cardLabel(13), 'A♦');
    });
  });

  // ── Initial deal ──────────────────────────────────────────────────────────

  group('initial deal', () {
    test('all 52 cards are distributed', () {
      final c = make();
      final s = c.read(solitaireProvider);
      final allCards = <int>{};
      allCards.addAll(s.stock);
      allCards.addAll(s.waste);
      for (final f in s.foundations) { allCards.addAll(f); }
      for (final t in s.tableaux) { allCards.addAll(t); }
      expect(allCards.length, 52);
    });

    test('tableau pile i has i+1 cards', () {
      final c = make();
      final s = c.read(solitaireProvider);
      for (int i = 0; i < 7; i++) {
        expect(s.tableaux[i].length, i + 1);
      }
    });

    test('faceDownCounts match expected', () {
      final c = make();
      final s = c.read(solitaireProvider);
      for (int i = 0; i < 7; i++) {
        // i face-down cards + 1 face-up
        expect(s.faceDownCounts[i], i);
      }
    });

    test('foundations are all empty', () {
      final c = make();
      final s = c.read(solitaireProvider);
      expect(s.foundations.every((f) => f.isEmpty), isTrue);
    });

    test('phase is playing', () {
      final c = make();
      expect(c.read(solitaireProvider).phase, SolitairePhase.playing);
    });
  });

  // ── Stock / Waste ─────────────────────────────────────────────────────────

  group('tapStock', () {
    test('moves top stock card to waste', () {
      final c = make();
      final before = c.read(solitaireProvider).stock.length;
      c.read(solitaireProvider.notifier).tapStock();
      final s = c.read(solitaireProvider);
      expect(s.stock.length, before - 1);
      expect(s.waste.length, 1);
    });

    test('increments move counter', () {
      final c = make();
      final before = c.read(solitaireProvider).moves;
      c.read(solitaireProvider.notifier).tapStock();
      expect(c.read(solitaireProvider).moves, before + 1);
    });

    test('tapping empty stock recycles waste back to stock', () {
      final c = make();
      // Drain entire stock
      while (c.read(solitaireProvider).stock.isNotEmpty) {
        c.read(solitaireProvider.notifier).tapStock();
      }
      final wasteCount = c.read(solitaireProvider).waste.length;
      expect(wasteCount, greaterThan(0));
      c.read(solitaireProvider.notifier).tapStock();
      final s = c.read(solitaireProvider);
      expect(s.stock.length, wasteCount);
      expect(s.waste, isEmpty);
    });

    test('tapping empty stock and empty waste does nothing', () {
      // Create container with no stock and no waste (edge case — game nearly won)
      // We simulate by draining all stock and waste is already empty
      final c = make();
      // Drain stock
      while (c.read(solitaireProvider).stock.isNotEmpty) {
        c.read(solitaireProvider.notifier).tapStock();
      }
      // Now recycle
      c.read(solitaireProvider.notifier).tapStock();
      // Drain stock again
      while (c.read(solitaireProvider).stock.isNotEmpty) {
        c.read(solitaireProvider.notifier).tapStock();
      }
      // Waste is now empty too (all moved), just verify no crash
      c.read(solitaireProvider.notifier).tapStock();
    });
  });

  // ── Tableau movement ──────────────────────────────────────────────────────

  group('tapTableau — selection', () {
    test('tapping face-down card does nothing', () {
      final c = make();
      // Pile 6 has 6 face-down cards + 1 face-up
      c.read(solitaireProvider.notifier).tapTableau(6, 0); // face-down
      expect(c.read(solitaireProvider).selection, isNull);
    });

    test('tapping face-up card selects it', () {
      final c = make();
      // The last card of each pile is face-up
      c.read(solitaireProvider.notifier).tapTableau(0, 0); // pile 0, only card
      final s = c.read(solitaireProvider);
      expect(s.selection, isNotNull);
      expect(s.selection!.pileIndex, 0);
    });

    test('tapping same pile twice deselects', () {
      final c = make();
      c.read(solitaireProvider.notifier).tapTableau(0, 0);
      expect(c.read(solitaireProvider).selection, isNotNull);
      c.read(solitaireProvider.notifier).tapTableau(0, 0);
      expect(c.read(solitaireProvider).selection, isNull);
    });
  });

  // ── Foundation rules ──────────────────────────────────────────────────────

  group('foundation placement', () {
    test('isWon returns false on initial state', () {
      final c = make();
      expect(c.read(solitaireProvider).isWon(), isFalse);
    });

    test('moves counter starts at 0', () {
      final c = make();
      expect(c.read(solitaireProvider).moves, 0);
    });
  });

  // ── newGame ───────────────────────────────────────────────────────────────

  group('newGame', () {
    test('resets move counter', () {
      final c = make();
      c.read(solitaireProvider.notifier).tapStock();
      c.read(solitaireProvider.notifier).newGame();
      expect(c.read(solitaireProvider).moves, 0);
    });

    test('resets to 52 cards distributed', () {
      final c = make();
      c.read(solitaireProvider.notifier).tapStock();
      c.read(solitaireProvider.notifier).newGame();
      final s = c.read(solitaireProvider);
      final allCards = <int>{};
      allCards.addAll(s.stock);
      allCards.addAll(s.waste);
      for (final f in s.foundations) { allCards.addAll(f); }
      for (final t in s.tableaux) { allCards.addAll(t); }
      expect(allCards.length, 52);
    });
  });

  // ── tapWaste ──────────────────────────────────────────────────────────────

  group('tapWaste', () {
    test('tapWaste after drawing sets waste selection', () {
      final c = make();
      c.read(solitaireProvider.notifier).tapStock(); // draw to waste
      c.read(solitaireProvider.notifier).tapWaste();
      final s = c.read(solitaireProvider);
      expect(s.selection, isNotNull);
      expect(s.selection!.pile, PileType.waste);
    });

    test('tapWaste twice clears selection', () {
      final c = make();
      c.read(solitaireProvider.notifier).tapStock();
      c.read(solitaireProvider.notifier).tapWaste();
      c.read(solitaireProvider.notifier).tapWaste();
      expect(c.read(solitaireProvider).selection, isNull);
    });

    test('tapStock clears selection', () {
      final c = make();
      c.read(solitaireProvider.notifier).tapStock();
      c.read(solitaireProvider.notifier).tapWaste(); // select
      c.read(solitaireProvider.notifier).tapStock(); // draw → should clear selection
      expect(c.read(solitaireProvider).selection, isNull);
    });
  });

  // ── tapFoundation ─────────────────────────────────────────────────────────

  group('tapFoundation', () {
    test('tapFoundation with no selection does nothing', () {
      final c = make();
      c.read(solitaireProvider.notifier).tapFoundation(0);
      expect(c.read(solitaireProvider).foundations[0], isEmpty);
    });

    test('tapFoundation with waste selected shows message or moves Ace', () {
      final c = make();
      c.read(solitaireProvider.notifier).tapStock();
      final wasteCard = c.read(solitaireProvider).waste.last;
      final suit = suitOf(wasteCard);
      c.read(solitaireProvider.notifier).tapWaste();
      c.read(solitaireProvider.notifier).tapFoundation(suit);
      final s = c.read(solitaireProvider);
      if (rankOf(wasteCard) == 0) {
        // Ace goes to foundation
        expect(s.foundations[suit].length, 1);
        expect(s.waste.contains(wasteCard), isFalse);
      } else {
        // Wrong rank: message, card stays
        expect(s.message, isNotEmpty);
        expect(s.waste.last, wasteCard);
      }
    });
  });

  // ── isWon direct state ────────────────────────────────────────────────────

  group('SolitaireState.isWon', () {
    test('isWon returns true when all four foundations have 13 cards', () {
      final clubs    = List.generate(13, (i) => i);
      final diamonds = List.generate(13, (i) => 13 + i);
      final hearts   = List.generate(13, (i) => 26 + i);
      final spades   = List.generate(13, (i) => 39 + i);
      final s = SolitaireState(
        stock: const [],
        waste: const [],
        foundations: [clubs, diamonds, hearts, spades],
        tableaux: List.generate(7, (_) => <int>[]),
        faceDownCounts: List.filled(7, 0),
        phase: SolitairePhase.won,
        moves: 52,
      );
      expect(s.isWon(), isTrue);
    });

    test('isWon returns false with partial foundations', () {
      final c = make();
      expect(c.read(solitaireProvider).isWon(), isFalse);
    });
  });

  // ── selectedCards helper ──────────────────────────────────────────────────

  group('SolitaireState.selectedCards', () {
    test('returns cards from cardIndex upward', () {
      final s = SolitaireState(
        stock: const [],
        waste: const [],
        foundations: List.generate(4, (_) => <int>[]),
        tableaux: [
          [10, 20, 30],
          ...List.generate(6, (_) => <int>[]),
        ],
        faceDownCounts: List.filled(7, 0),
        phase: SolitairePhase.playing,
        moves: 0,
      );
      expect(s.selectedCards(0, 1), [20, 30]);
    });
  });

  // ── autoSendToFoundation (GB14 — one-tap foundation shortcut) ────────────

  group('autoSendToFoundation (GB14)', () {
    SolitaireState seed({
      List<int> waste = const [],
      List<List<int>>? tableaux,
      List<List<int>>? foundations,
    }) =>
        SolitaireState(
          stock: const [],
          waste: waste,
          foundations: foundations ?? List.generate(4, (_) => <int>[]),
          tableaux: tableaux ?? List.generate(7, (_) => <int>[]),
          faceDownCounts: List.filled(7, 0),
          phase: SolitairePhase.playing,
          moves: 0,
        );

    test(
        'waste: an eligible top card is sent to the foundation in one call '
        '— previously this needed an explicit select-then-tap-foundation '
        'sequence', () {
      final c = _makeSeeded(seed(waste: const [0])); // A♣
      c.read(solitaireProvider.notifier).autoSendToFoundation(PileType.waste, 0);
      final s = c.read(solitaireProvider);
      expect(s.waste, isEmpty);
      expect(s.foundations[0], [0]);
      expect(s.moves, 1);
    });

    test('waste: an ineligible top card is left untouched (no-op)', () {
      final c = _makeSeeded(seed(waste: const [1])); // 2♣ — foundation needs Ace first
      c.read(solitaireProvider.notifier).autoSendToFoundation(PileType.waste, 0);
      final s = c.read(solitaireProvider);
      expect(s.waste, [1]);
      expect(s.foundations[0], isEmpty);
      expect(s.moves, 0);
    });

    test('tableau: an eligible top card is sent to the foundation in one call', () {
      final c = _makeSeeded(seed(tableaux: [
        [0], // A♣
        ...List.generate(6, (_) => <int>[]),
      ]));
      c.read(solitaireProvider.notifier).autoSendToFoundation(PileType.tableau, 0);
      final s = c.read(solitaireProvider);
      expect(s.tableaux[0], isEmpty);
      expect(s.foundations[0], [0]);
      expect(s.moves, 1);
    });

    test('tableau: an ineligible top card is left untouched (no-op)', () {
      final c = _makeSeeded(seed(tableaux: [
        [1], // 2♣ — foundation needs Ace first
        ...List.generate(6, (_) => <int>[]),
      ]));
      c.read(solitaireProvider.notifier).autoSendToFoundation(PileType.tableau, 0);
      final s = c.read(solitaireProvider);
      expect(s.tableaux[0], [1]);
      expect(s.foundations[0], isEmpty);
      expect(s.moves, 0);
    });

    test('an empty waste or tableau pile is a safe no-op', () {
      final c = _makeSeeded(seed());
      c.read(solitaireProvider.notifier).autoSendToFoundation(PileType.waste, 0);
      c.read(solitaireProvider.notifier).autoSendToFoundation(PileType.tableau, 3);
      expect(c.read(solitaireProvider).moves, 0);
    });
  });
}
