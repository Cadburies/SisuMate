# Store listing assets

Copy-paste and upload these into App Store Connect and Google Play Console.

## Text

| File | Store field | Limit | Length |
| --- | --- | --- | --- |
| `short-description.txt` | Play **short description** | 80 | 72 |
| `full-description.txt` | Play **full description** and App Store **description** | 4000 | ~2070 |
| `app-store-subtitle.txt` | App Store **subtitle** | 30 | 26 |
| `promotional-text.txt` | App Store **promotional text** | 170 | 153 |

Suggested App Store / Play **name**: `Sisu Mate` (9 characters).

## Graphics

| File | Use | Size |
| --- | --- | --- |
| `app-icon-512.png` | Play hi-res icon | 512×512 |
| `app-icon-1024.png` | App Store icon | 1024×1024 |
| `feature-graphic.png` | Play feature graphic (required) | 1024×500 |
| `play-screenshots/*.jpg` | **Play phone screenshots only** (8) | 1080×1920 JPEG, 9:16 |
| `screenshots-iphone-69/*.png` | App Store 6.9" iPhone only | 1320×2868 — Play will reject these |

Upload screenshots in this order (first three show in App Store search):

1. Home
2. Checklists
3. Shopping
4. Weather
5. Chef
6. Games
7. Cocktails
8. Anchor Alarm

These are marketing frames of the real module layout and copy. If a store reviewer asks for raw device captures, shoot the same eight screens on a phone and replace the files.

Regenerate from `_src/listing.html` with `_src/render.sh`.

## Forms, URLs, questionnaires

Copy-paste answers for App Privacy, Data safety, keywords, age rating, export compliance, review notes, plus hostable privacy/support/terms pages, are in `forms/`. Start at `forms/README.md`.
