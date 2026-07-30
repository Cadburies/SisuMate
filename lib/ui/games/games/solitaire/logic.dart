import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _rng = Random();

// Card encoding: 0-51.  suit = card ~/ 13 (0=♣ 1=♦ 2=♥ 3=♠)  rank = card % 13 (0=A … 12=K)
int suitOf(int c) => c ~/ 13;
int rankOf(int c) => c % 13;
bool isRed(int c) => suitOf(c) == 1 || suitOf(c) == 2;

const _rankLabels = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
const _suitSymbols = ['♣','♦','♥','♠'];
String cardLabel(int c) => '${_rankLabels[rankOf(c)]}${_suitSymbols[suitOf(c)]}';

enum SolitairePhase { playing, won }

enum PileType { stock, waste, foundation, tableau }

class Selection {
  final PileType pile;
  final int pileIndex;   // foundation 0-3, tableau 0-6 (ignored for waste/stock)
  final int cardIndex;   // index within that pile's visible stack
  const Selection(this.pile, this.pileIndex, this.cardIndex);
}

class SolitaireState {
  final List<int> stock;
  final List<int> waste;
  final List<List<int>> foundations; // 4 piles, each suit's Ace→King sequence
  final List<List<int>> tableaux;    // 7 piles
  final List<int> faceDownCounts;    // how many cards at bottom of each tableau are face-down
  final Selection? selection;
  final SolitairePhase phase;
  final int moves;
  final String message;

  const SolitaireState({
    required this.stock,
    required this.waste,
    required this.foundations,
    required this.tableaux,
    required this.faceDownCounts,
    required this.phase,
    required this.moves,
    this.selection,
    this.message = '',
  });

  SolitaireState copyWith({
    List<int>? stock,
    List<int>? waste,
    List<List<int>>? foundations,
    List<List<int>>? tableaux,
    List<int>? faceDownCounts,
    Selection? Function()? selection,
    SolitairePhase? phase,
    int? moves,
    String? message,
  }) =>
      SolitaireState(
        stock: stock ?? this.stock,
        waste: waste ?? this.waste,
        foundations: foundations ?? this.foundations,
        tableaux: tableaux ?? this.tableaux,
        faceDownCounts: faceDownCounts ?? this.faceDownCounts,
        selection: selection != null ? selection() : this.selection,
        phase: phase ?? this.phase,
        moves: moves ?? this.moves,
        message: message ?? this.message,
      );

  /// Cards from cardIndex upward in a tableau pile that are face-up.
  List<int> selectedCards(int pileIdx, int cardIdx) {
    return tableaux[pileIdx].sublist(cardIdx);
  }

  bool isWon() => foundations.every((f) => f.length == 13);
}

class SolitaireNotifier extends Notifier<SolitaireState> {
  @override
  SolitaireState build() => _deal();

  SolitaireState _deal() {
    final deck = List.generate(52, (i) => i)..shuffle(_rng);
    final tableaux = List.generate(7, (_) => <int>[]);
    final faceDown = List.filled(7, 0);
    int idx = 0;
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < i; j++) {
        tableaux[i].add(deck[idx++]);
        faceDown[i]++;
      }
      tableaux[i].add(deck[idx++]); // top card face up
    }
    return SolitaireState(
      stock: deck.sublist(idx),
      waste: [],
      foundations: List.generate(4, (_) => <int>[]),
      tableaux: tableaux,
      faceDownCounts: faceDown,
      phase: SolitairePhase.playing,
      moves: 0,
    );
  }

  void tapStock() {
    final s = state;
    if (s.stock.isEmpty) {
      if (s.waste.isEmpty) return;
      // Recycle waste back to stock (face-down = reversed)
      state = s.copyWith(
        stock: s.waste.reversed.toList(),
        waste: [],
      );
      return;
    }
    final newStock = [...s.stock];
    final newWaste = [...s.waste, newStock.removeLast()];
    state = s.copyWith(
      stock: newStock,
      waste: newWaste,
      selection: () => null,
      moves: s.moves + 1,
    );
  }

  void tapWaste() {
    if (state.waste.isEmpty) return;
    // Toggle selection
    if (state.selection?.pile == PileType.waste) {
      state = state.copyWith(selection: () => null, message: '');
      return;
    }
    state = state.copyWith(
      selection: () => Selection(PileType.waste, 0, state.waste.length - 1),
      message: 'Waste card selected — tap a column or foundation.',
    );
  }

  void tapFoundation(int i) {
    final s = state;
    if (s.selection == null) return;
    final sel = s.selection!;
    int card;
    if (sel.pile == PileType.waste) {
      if (s.waste.isEmpty) return;
      card = s.waste.last;
    } else if (sel.pile == PileType.tableau) {
      final pile = s.tableaux[sel.pileIndex];
      if (sel.cardIndex != pile.length - 1) return; // only single card to foundation
      card = pile.last;
    } else {
      return;
    }
    if (_canPlaceOnFoundation(card, i)) {
      _moveToFoundation(card, sel, i);
    } else {
      final f = s.foundations[i];
      final needed = f.isEmpty
          ? 'A${_suitSymbols[i]}'
          : cardLabel((rankOf(f.last) + 1) + suitOf(f.last) * 13);
      state = s.copyWith(message: 'Foundation needs $needed next.');
    }
  }

  void tapTableau(int pileIdx, int cardIdx) {
    final s = state;
    final pile = s.tableaux[pileIdx];
    final faceDown = s.faceDownCounts[pileIdx];
    if (cardIdx < faceDown) return; // can't interact with face-down cards

    if (s.selection != null) {
      final sel = s.selection!;
      int topCard;
      List<int> movingCards;
      if (sel.pile == PileType.waste) {
        if (s.waste.isEmpty) { state = s.copyWith(selection: () => null); return; }
        topCard = s.waste.last;
        movingCards = [topCard];
      } else if (sel.pile == PileType.tableau) {
        final fromPile = s.tableaux[sel.pileIndex];
        movingCards = fromPile.sublist(sel.cardIndex);
        topCard = movingCards.first;
      } else {
        state = s.copyWith(selection: () => null);
        return;
      }

      if (_canPlaceOnTableau(topCard, pileIdx)) {
        _moveToTableau(movingCards, sel, pileIdx);
        return;
      }

      // Placement failed
      if (sel.pile == PileType.waste) {
        // Keep waste selection — show why placement failed
        final top = pile.isEmpty ? null : pile.last;
        final reason = top == null
            ? 'Only Kings can start an empty column.'
            : 'Can\'t place ${cardLabel(topCard)} on ${cardLabel(top)} — need alternating color, one rank lower.';
        state = s.copyWith(message: reason);
        return;
      }
      // Same tableau pile: deselect
      if (sel.pile == PileType.tableau && sel.pileIndex == pileIdx) {
        state = s.copyWith(selection: () => null, message: '');
        return;
      }
      // Different tableau pile with invalid move: re-select tapped card
    }

    // Select card at cardIdx in this tableau
    if (cardIdx < faceDown || pile.isEmpty) return;
    state = s.copyWith(
      selection: () => Selection(PileType.tableau, pileIdx, cardIdx),
      message: 'Card selected — tap destination column or foundation.',
    );
  }

  void tapEmptyTableau(int pileIdx) {
    final s = state;
    if (s.selection == null) return;
    final sel = s.selection!;
    List<int> movingCards;
    if (sel.pile == PileType.waste) {
      if (s.waste.isEmpty) return;
      movingCards = [s.waste.last];
    } else if (sel.pile == PileType.tableau) {
      final fromPile = s.tableaux[sel.pileIndex];
      movingCards = fromPile.sublist(sel.cardIndex);
    } else { return; }
    // Only Kings can go on empty tableau
    if (rankOf(movingCards.first) != 12) return;
    _moveToTableau(movingCards, sel, pileIdx);
  }

  /// GB14: one-tap (double-tap) shortcut — sends the top card of [pile]
  /// straight to its matching foundation if eligible, without requiring the
  /// manual select-then-tap-foundation sequence. No-op if the top card
  /// can't currently go to a foundation.
  void autoSendToFoundation(PileType pile, int pileIdx) {
    final s = state;
    int card;
    Selection sel;
    if (pile == PileType.waste) {
      if (s.waste.isEmpty) return;
      card = s.waste.last;
      sel = Selection(PileType.waste, 0, s.waste.length - 1);
    } else if (pile == PileType.tableau) {
      final p = s.tableaux[pileIdx];
      if (p.isEmpty) return;
      card = p.last;
      sel = Selection(PileType.tableau, pileIdx, p.length - 1);
    } else {
      return;
    }
    final foundationIdx = suitOf(card);
    if (!_canPlaceOnFoundation(card, foundationIdx)) return;
    _moveToFoundation(card, sel, foundationIdx);
  }

  bool _canPlaceOnFoundation(int card, int foundationIdx) {
    final f = state.foundations[foundationIdx];
    if (suitOf(card) != foundationIdx) return false;
    if (f.isEmpty) return rankOf(card) == 0; // Ace
    return rankOf(card) == rankOf(f.last) + 1;
  }

  bool _canPlaceOnTableau(int card, int pileIdx) {
    final pile = state.tableaux[pileIdx];
    if (pile.isEmpty) return rankOf(card) == 12; // King on empty
    final top = pile.last;
    return isRed(card) != isRed(top) && rankOf(card) == rankOf(top) - 1;
  }

  void _moveToFoundation(int card, Selection sel, int foundationIdx) {
    final s = state;
    final newFoundations = s.foundations.map((f) => [...f]).toList();
    newFoundations[foundationIdx].add(card);

    List<int> newWaste = [...s.waste];
    final newTableaux = s.tableaux.map((p) => [...p]).toList();
    final newFaceDown = [...s.faceDownCounts];

    if (sel.pile == PileType.waste) {
      newWaste.removeLast();
    } else if (sel.pile == PileType.tableau) {
      newTableaux[sel.pileIndex].removeLast();
      if (newTableaux[sel.pileIndex].isNotEmpty &&
          newFaceDown[sel.pileIndex] >= newTableaux[sel.pileIndex].length) {
        newFaceDown[sel.pileIndex] = newTableaux[sel.pileIndex].length - 1;
        if (newFaceDown[sel.pileIndex] < 0) newFaceDown[sel.pileIndex] = 0;
      }
    }

    state = s.copyWith(
      waste: newWaste,
      foundations: newFoundations,
      tableaux: newTableaux,
      faceDownCounts: newFaceDown,
      selection: () => null,
      moves: s.moves + 1,
      message: newFoundations.every((f) => f.length == 13)
          ? 'You win!'
          : '${cardLabel(card)} moved to foundation!',
      phase: newFoundations.every((f) => f.length == 13) ? SolitairePhase.won : null,
    );
  }

  void _moveToTableau(List<int> cards, Selection sel, int toPileIdx) {
    final s = state;
    final newTableaux = s.tableaux.map((p) => [...p]).toList();
    final newFaceDown = [...s.faceDownCounts];
    List<int> newWaste = [...s.waste];

    if (sel.pile == PileType.waste) {
      newWaste.removeLast();
    } else if (sel.pile == PileType.tableau) {
      final fromLen = newTableaux[sel.pileIndex].length;
      newTableaux[sel.pileIndex].removeRange(sel.cardIndex, fromLen);
      final remaining = newTableaux[sel.pileIndex].length;
      if (remaining > 0 && newFaceDown[sel.pileIndex] >= remaining) {
        newFaceDown[sel.pileIndex] = remaining - 1;
        if (newFaceDown[sel.pileIndex] < 0) newFaceDown[sel.pileIndex] = 0;
      } else if (remaining == 0) {
        newFaceDown[sel.pileIndex] = 0;
      }
    }

    newTableaux[toPileIdx].addAll(cards);
    state = s.copyWith(
      waste: newWaste,
      tableaux: newTableaux,
      faceDownCounts: newFaceDown,
      selection: () => null,
      moves: s.moves + 1,
      message: cards.length > 1 ? 'Moved ${cards.length} cards.' : 'Moved ${cardLabel(cards.first)}.',
    );
  }

  static String computeHint(SolitaireState s) {
    // Check waste → foundation
    if (s.waste.isNotEmpty) {
      final card = s.waste.last;
      final suit = suitOf(card);
      final f = s.foundations[suit];
      final canF = suitOf(card) == suit &&
          (f.isEmpty ? rankOf(card) == 0 : rankOf(card) == rankOf(f.last) + 1);
      if (canF) return 'Move ${cardLabel(card)} from waste to ${_suitSymbols[suit]} foundation.';
    }
    // Check waste → tableau
    if (s.waste.isNotEmpty) {
      final card = s.waste.last;
      for (int i = 0; i < 7; i++) {
        final pile = s.tableaux[i];
        if (pile.isEmpty) {
          if (rankOf(card) == 12) return 'Move ${cardLabel(card)} (King) to empty column ${i + 1}.';
        } else {
          final top = pile.last;
          if (isRed(card) != isRed(top) && rankOf(card) == rankOf(top) - 1) {
            return 'Move ${cardLabel(card)} from waste to column ${i + 1}.';
          }
        }
      }
    }
    // Check tableau → foundation
    for (int pi = 0; pi < 7; pi++) {
      final pile = s.tableaux[pi];
      if (pile.isEmpty) continue;
      final card = pile.last;
      final suit = suitOf(card);
      final f = s.foundations[suit];
      if (f.isEmpty ? rankOf(card) == 0 : rankOf(card) == rankOf(f.last) + 1) {
        return 'Move ${cardLabel(card)} from column ${pi + 1} to foundation.';
      }
    }
    // Check tableau → tableau
    for (int from = 0; from < 7; from++) {
      final pile = s.tableaux[from];
      if (pile.isEmpty) continue;
      final fd = s.faceDownCounts[from];
      for (int ci = fd; ci < pile.length; ci++) {
        final card = pile[ci];
        for (int to = 0; to < 7; to++) {
          if (to == from) continue;
          final dest = s.tableaux[to];
          if (dest.isEmpty) {
            if (rankOf(card) == 12 && ci > 0) {
              return 'Move ${cardLabel(card)} stack to empty column ${to + 1}.';
            }
          } else {
            final top = dest.last;
            if (isRed(card) != isRed(top) && rankOf(card) == rankOf(top) - 1) {
              return 'Move ${cardLabel(card)} from column ${from + 1} to column ${to + 1}.';
            }
          }
        }
      }
    }
    if (s.stock.isNotEmpty) return 'Tap stock to draw a card.';
    if (s.waste.isNotEmpty) return 'Recycle the waste pile.';
    return 'No moves found — try a new game.';
  }

  void newGame() => state = _deal();
}

final solitaireProvider =
    NotifierProvider<SolitaireNotifier, SolitaireState>(SolitaireNotifier.new);
