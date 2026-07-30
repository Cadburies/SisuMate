import 'game_help_screen.dart';

const backgammonHelp = GameHelpData(
  gameName: 'Backgammon',
  iconPath: 'assets/games/games/backgammon/icon.jpg',
  tagline: 'Race your 15 pieces around the board and bear them off before your opponent!',
  sections: [
    HelpSection('Setup & Movement', [
      'You (white) move pieces from point 24 → 1 (right to left).',
      'AI (black) moves pieces from point 1 → 24 (left to right).',
      'Roll two dice each turn and move pieces the shown number of points.',
      'Doubles give you 4 moves instead of 2.',
    ]),
    HelpSection('Hitting & the Bar', [
      'Landing on a point with exactly ONE opponent piece hits it — that piece goes to the Bar.',
      'A player with pieces on the Bar MUST re-enter them before any other move.',
      'A point with TWO or more opponent pieces is blocked — you cannot land there.',
    ]),
    HelpSection('Bearing Off', [
      'Once ALL your pieces are in your home board (points 1–6), you can bear them off.',
      'Roll a die and remove a piece from that point number.',
      'If no piece sits on that exact point, move a piece from a higher point instead.',
      'If the number is higher than any piece you have, bear off your highest piece.',
    ]),
    HelpSection('Doubling Cube', [
      'Before rolling, you may offer to double the stake (×2, ×4, … up to ×64).',
      'The opponent Accepts (cube flips to them; play continues at the new stake) or Declines (you win the current stake).',
      'Only the cube owner may redouble. Centered cube: either player may open.',
    ]),
    HelpSection('Winning', [
      'First player to bear off all 15 pieces wins (worth the current cube value).',
      'Tap "Roll" to start your turn; tap a piece then its destination to move.',
    ]),
  ],
);

const checkersHelp = GameHelpData(
  gameName: 'Checkers',
  iconPath: 'assets/games/games/checkers/icon.jpg',
  tagline: 'Capture all of your opponent\'s pieces to win!',
  sections: [
    HelpSection('Basic Movement', [
      'Your pieces (red) start at the top 3 rows; AI (black) at the bottom 3.',
      'Pieces move diagonally one square forward toward the opponent\'s side.',
      'You can only move on dark squares.',
      'Tap a piece to select it, then tap the destination square.',
    ]),
    HelpSection('Capturing', [
      'Jump over an adjacent opponent piece diagonally to capture it.',
      'The captured piece is removed from the board.',
      'If a jump is available, you MUST take it — mandatory capture rule.',
      'After a jump, if another jump is possible with the same piece, you MUST take it (chain jump).',
    ]),
    HelpSection('Kings', [
      'When your piece reaches the far row (row 8), it becomes a King.',
      'Kings can move and capture in both forward and backward directions.',
      'AI pieces also become Kings when they reach row 1.',
    ]),
    HelpSection('Winning', [
      'Win by capturing ALL opponent pieces, or leaving them with no valid moves.',
    ]),
  ],
);

const cribbageHelp = GameHelpData(
  gameName: 'Cribbage',
  iconPath: 'assets/games/games/cribbage/icon.jpg',
  tagline: 'Score points through clever pegging and hand counting — first to 121 wins!',
  sections: [
    HelpSection('Setup', [
      'Each player is dealt 6 cards and discards 2 to the "crib".',
      'The crib belongs to the dealer — extra scoring after the round.',
      'A "starter" card is cut from the deck. Jack as starter = 2 pts for dealer (Nibs).',
    ]),
    HelpSection('Pegging', [
      'Players alternate playing cards face-up, calling the running total.',
      'Score 2 pts for reaching exactly 15 or 31.',
      'Score 2 pts for a pair, 6 for three of a kind, 12 for four of a kind.',
      'Score the length of any run (sequence) formed by the last cards played.',
      '"Go" means you cannot play without exceeding 31; the other player keeps going.',
      '1 pt for the last card played (Last Go).',
    ]),
    HelpSection('Counting Hands', [
      'After pegging, count your hand + starter card:',
      '2 pts per combination that sums to 15.',
      '2 pts per pair (6 for 3-of-a-kind, 12 for 4-of-a-kind).',
      'Run points equal the length of any sequence (minimum 3 cards).',
      '4 pts for a 4-card flush; 5 pts if starter matches the suit.',
      '1 pt for Jack of the same suit as the starter (Nobs).',
      'Dealer scores their hand, then counts the crib.',
    ]),
    HelpSection('Winning', [
      'First player to reach 121 points wins.',
      'Non-dealer counts first — so they can win mid-hand.',
    ]),
  ],
);

const dudoHelp = GameHelpData(
  gameName: 'Dudo',
  iconPath: 'assets/games/games/dudo/icon.jpg',
  tagline: 'Bid on dice hidden under cups — bluff smart, challenge wisely!',
  sections: [
    HelpSection('Setup', [
      'Each player starts with 5 dice hidden under a cup.',
      'Highest single-die roll goes first (re-roll ties).',
    ]),
    HelpSection('Bidding', [
      'The active player bids: "There are at least X dice showing face Y across ALL players."',
      'Aces (1s) are WILD — they count toward any non-ace bid.',
      'You may NOT start the first round with an ace bid (unless you have only 1 die left).',
      'Each raise must increase the quantity, or keep the same quantity and increase the face.',
      'Switching to aces: new quantity ≥ ⌈old quantity ÷ 2⌉.',
      'Switching from aces to another face: new quantity ≥ 2 × ace quantity + 1.',
    ]),
    HelpSection('Calling Dudo (Challenge)', [
      'Say "Dudo!" to challenge the last bid.',
      'All dice are revealed and counted.',
      'If the actual count ≥ bid quantity → bid was honest → YOU (the challenger) lose 1 die.',
      'If the actual count < bid quantity → bid was a bluff → the BIDDER loses 1 die.',
    ]),
    HelpSection('Spot On (Calzo)', [
      'Say "Spot On" if you believe the count is EXACTLY right.',
      'If correct → you GAIN 1 die (up to 5 max).',
      'If wrong → you LOSE 1 die.',
      'The bidder never loses a die on a Spot On call.',
    ]),
    HelpSection('Winning', [
      'Lose all your dice → you are eliminated.',
      'Last player with dice remaining wins!',
    ]),
  ],
);

const liarsDiceHelp = GameHelpData(
  gameName: "Liar's Dice",
  iconPath: 'assets/games/games/liars_dice/icon.jpg',
  tagline: 'Declare the best poker hand you can — or bluff! First to lose all counters is out.',
  sections: [
    HelpSection('Overview', [
      'Each player has 5 dice and 10 counters.',
      'Roll your dice secretly. Declare a poker hand rank (e.g. Full House of 5s).',
      'The next player must accept (and try to beat it) or challenge.',
    ]),
    HelpSection('Hand Rankings (best → worst)', [
      '1. Five of a Kind',
      '2. Four of a Kind',
      '3. Full House',
      '4. High Straight (2–3–4–5–6)',
      '5. Low Straight (1–2–3–4–5)',
      '6. Three of a Kind',
      '7. Two Pair',
      '8. One Pair',
      '9. High Card',
    ]),
    HelpSection('Declaring & Challenging', [
      'Each new declaration must be HIGHER than the previous one (better rank or same rank higher face).',
      'If you ACCEPT: the dice pass to you and you must roll and declare something higher.',
      'If you CHALLENGE: dice are revealed.',
      '  • Bluff (declared rank better than actual) → declarer loses 1 counter.',
      '  • Honest (actual rank ≥ declared) → challenger loses 1 counter.',
      'The challenger always starts the next round.',
    ]),
    HelpSection('Winning', [
      'A player who loses their last counter is eliminated.',
      'Last player with counters remaining wins!',
    ]),
  ],
);

const pokerHelp = GameHelpData(
  gameName: 'Poker',
  iconPath: 'assets/games/games/poker/icon.jpg',
  tagline: '5-Card Draw — build the best hand and outbluff the AI!',
  sections: [
    HelpSection('Hand Rankings (worst → best)', [
      'High Card → One Pair → Two Pair → Three of a Kind',
      'Straight → Flush → Full House → Four of a Kind',
      'Straight Flush → Royal Flush (10-J-Q-K-A same suit)',
    ]),
    HelpSection('Round Structure', [
      'Both players pay an ante (\$10) to start.',
      'Round 1 Betting: Bet (+\$20), Check (stay even), or Fold (forfeit).',
      'After betting, select cards to discard (tap them) then tap "Confirm Draw".',
      'Round 2 Betting: another round of Bet / Check / Fold.',
      'Showdown: best hand wins the pot.',
    ]),
    HelpSection('Tips', [
      'Keep pairs, trips, and quads — discard the rest.',
      'A pair is worth holding; three-of-a-kind is very strong.',
      'Fold if you have a weak hand and the AI bets.',
      'You start with \$500 chips; AI also starts with \$500.',
    ]),
  ],
);

const solitaireHelp = GameHelpData(
  gameName: 'Solitaire',
  iconPath: 'assets/games/games/solitaire/icon.jpg',
  tagline: 'Klondike Solitaire — stack all 52 cards onto the 4 foundations to win!',
  sections: [
    HelpSection('Layout', [
      'Stock (top-left): Tap to flip one card at a time onto the Waste pile.',
      'Waste (next to Stock): Top card is available to play.',
      'Foundations (top-right, 4 piles): Build Ace → King, one per suit.',
      'Tableau (7 columns): Build DOWN in alternating red/black colors.',
    ]),
    HelpSection('Moving Cards', [
      'Tap a card to select it, then tap the destination (tableau pile or foundation).',
      'Double-tap the Waste top or a tableau top card to auto-send it to its foundation when legal (GB14).',
      'You can move a stack of face-up cards together.',
      'Face-down cards are revealed when the card above them is moved.',
      'Only a King (or a stack starting with a King) can go on an empty tableau column.',
    ]),
    HelpSection('Stock & Waste', [
      'Tap the Stock to deal one card to the Waste.',
      'When the Stock is empty, tap it again to recycle the Waste back.',
      'The Waste cycles as many times as you need.',
    ]),
    HelpSection('Winning', [
      'Move all 52 cards to the 4 foundation piles (Ace through King, by suit).',
    ]),
  ],
);

const unoHelp = GameHelpData(
  gameName: 'Uno',
  iconPath: 'assets/games/games/uno/icon.jpg',
  tagline: 'Match colors or numbers to empty your hand — first to play all cards wins!',
  sections: [
    HelpSection('Basic Play', [
      'Match the top discard card by COLOR or by NUMBER/VALUE.',
      'Tap a card to select it, then tap "Play" — or tap "Draw" if you have no match.',
      'If the drawn card is playable, you can play it immediately.',
    ]),
    HelpSection('Action Cards', [
      'Skip: the next player (AI) misses their turn.',
      'Reverse: in 2-player games, acts like a Skip.',
      '+2 Draw Two: AI draws 2 cards and is skipped.',
      'Wild: play on any color; choose the new color.',
      'Wild +4: AI draws 4 cards and is skipped; choose the new color.',
    ]),
    HelpSection('Uno!', [
      'When you have exactly 1 card left, the game announces UNO! automatically.',
      'If you play your last card, you win the round.',
    ]),
    HelpSection('Strategy', [
      'Save Wild and +4 cards for when you really need them.',
      'Use Skip and +2 to stop the AI from going out.',
      'Pay attention to the current color — don\'t waste a color match unnecessarily.',
    ]),
  ],
);

const yatzyHelp = GameHelpData(
  gameName: 'Yatzy',
  iconPath: 'assets/games/games/yatzy/icon.jpg',
  tagline: 'Roll 5 dice up to 3 times and score in one category — most points wins!',
  sections: [
    HelpSection('How a Turn Works', [
      'Tap "Roll" to roll all 5 dice.',
      'Tap dice you want to KEEP (they turn green), then Roll again.',
      'You may roll up to 3 times per turn.',
      'After rolling, tap a scoring category to record your score.',
    ]),
    HelpSection('Upper Section (sum of matching dice)', [
      'Ones through Sixes: score only the dice matching that number.',
      'Bonus: +50 points if your upper section total is ≥ 63.',
    ]),
    HelpSection('Lower Section', [
      'Three of a Kind: 3+ matching dice → sum of ALL dice.',
      'Four of a Kind: 4+ matching dice → sum of ALL dice.',
      'Full House (3+2): exactly 25 points.',
      'Small Straight (4 in a row): 30 points.',
      'Large Straight (5 in a row): 40 points.',
      'Yatzy (5 of a kind): 50 points.',
      'Chance: sum of ALL 5 dice (use for bad rolls).',
    ]),
    HelpSection('Strategy', [
      'Use "Chance" as a dump category when you have a weak roll.',
      'Aim for Ones–Sixes totals above 63 to earn the bonus.',
      'Yatzy is worth holding 4 of a kind for an extra roll.',
    ]),
  ],
);
