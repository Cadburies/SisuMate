#!/usr/bin/env python3
"""Process lib/recipe_import.json -> assets/seed/menus_import_seed.json.

- Base quantities for **2 people** (app servings 1/2/4/6/10 scale from that base).
- Ensure ingredients cover foods named in description/instructions.
- Add a guest-friendly **story** with wine or beer pairing (Caribbean-friendly
  substitutes: colour + grape / style, not specific vintage).
- Map meal course types (main/side/braai/...) into cuisine tags; recipeType is menu.

Regenerate:
  python3 tool/generate_menus_import_seed.py
"""

from __future__ import annotations

import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "lib" / "recipe_import.json"
OUT = ROOT / "assets" / "seed" / "menus_import_seed.json"

COURSE_LABEL = {
    "main": "Main",
    "side": "Side",
    "dessert": "Dessert",
    "snack": "Snack",
    "braai": "Braai",
    "breakfast": "Breakfast",
    "preserves": "Preserves",
    "appetizer": "Appetizer",
}

# Phrases in prose -> ingredient to ensure is listed (name, qty for 2p, unit).
PROSE_INGREDIENTS: list[tuple[str, float | None, str | None]] = [
    ("proscuitto", 4, "slices"),  # typo guard
    ("prosciutto", 4, "slices"),
    ("arugula", 40, "g"),
    ("rocket", 40, "g"),
    ("blue cheese", 40, "g"),
    ("parmesan", 30, "g"),
    ("puff pastry", 1, "sheet"),
    ("mushroom", 150, "g"),
    ("mushrooms", 150, "g"),
    ("duxelles", 150, "g"),
    ("pap", 200, "g"),
    ("tomato relish", 80, "ml"),
    ("jasmine rice", 160, "g"),
    ("rice", 160, "g"),
    ("lemon", 1, "pieces"),
    ("lime", 1, "pieces"),
    ("garlic", 2, "cloves"),
    ("onion", 1, "medium"),
    ("shallot", 2, "pieces"),
    ("butter", 40, "g"),
    ("olive oil", 30, "ml"),  # 2 tbsp
    ("cream", 100, "ml"),
    ("egg", 2, "count"),
    ("eggs", 2, "count"),
    ("flour", 50, "g"),
    ("sugar", 50, "g"),
    ("honey", 30, "ml"),  # 2 tbsp
    ("soy sauce", 30, "ml"),  # 2 tbsp
    ("ginger", 15, "g"),
    ("chilli", 1, "count"),
    ("chili", 1, "count"),
    ("cilantro", 10, "g"),
    ("coriander", 5, "ml"),  # 1 tsp
    ("basil", 10, "g"),
    ("mint", 10, "g"),
    ("thyme", 5, "ml"),  # 1 tsp
    ("rosemary", 5, "ml"),  # 1 tsp
    ("parsley", 10, "g"),
    ("potato", 300, "g"),
    ("potatoes", 300, "g"),
    ("tomato", 2, "medium"),
    ("tomatoes", 2, "medium"),
    ("avocado", 1, "count"),
    ("mango", 1, "count"),
    ("pineapple", 200, "g"),
    ("coconut", 50, "g"),
    ("bacon", 80, "g"),
    ("chicken stock", 200, "ml"),
    ("stock", 200, "ml"),
    ("wine", 100, "ml"),
    ("breadcrumbs", 50, "g"),
    ("panko", 50, "g"),
    ("mustard", 15, "ml"),  # 1 tbsp
    ("mayonnaise", 30, "ml"),  # 2 tbsp
    ("vinegar", 15, "ml"),  # 1 tbsp
    ("dressing", 30, "ml"),  # 2 tbsp
    ("vinaigrette", 30, "ml"),  # 2 tbsp
]

# Heuristic pairings: (keyword in name/cuisine/course, story fragment).
PAIRINGS: list[tuple[list[str], str, str]] = [
    # keywords, primary pairing line, Caribbean substitute line
    (
        ["braai", "bbq", "barbecue", "wors", "steak", "rib", "grill"],
        "Pair with a cold lager or pale ale - carbonation and hop bitterness cut fat from grilled meat.",
        "If you cannot find the same beer, any crisp lager or light pale ale works; avoid heavy stouts.",
    ),
    (
        ["dessert", "chocolate", "cake", "tart", "pudding", "ice cream"],
        "A late-harvest white or tawny-style dessert wine echoes sweetness without fighting it.",
        "Substitute: any sweet white (late harvest / Muscat style) slightly chilled; or skip alcohol and serve strong coffee.",
    ),
    (
        ["breakfast", "pancake", "omelette", "egg", "toast"],
        "Coffee or a light breakfast stout is classic; for wine, a dry sparkling white feels festive on deck.",
        "Substitute: any dry sparkling white (Cava / Prosecco style) or fresh orange juice.",
    ),
    (
        ["preserve", "jam", "chutney", "pickle"],
        "Serve with a cheese board and a glass of dry white or light red - acidity balances sugar.",
        "Substitute: any dry white (Sauvignon Blanc / Chenin style) or light red (Pinot Noir style).",
    ),
    (
        ["seafood", "fish", "prawn", "shrimp", "mussel", "calamari", "tuna", "salmon", "bass"],
        "A crisp Sauvignon Blanc or dry Riesling lifts citrus and brine.",
        "Substitute: any dry white with citrus notes (Sauvignon Blanc / unoaked Chardonnay / dry Riesling).",
    ),
    (
        ["thai", "curry", "spicy", "chilli", "chili", "sambal"],
        "Off-dry Gewurztraminer or Riesling calms chilli heat; a cold lager also works hard.",
        "Substitute: slightly sweet white (Riesling / Gewurztraminer style) or ice-cold lager.",
    ),
    (
        ["italian", "pasta", "pizza", "risotto", "tomato"],
        "Chianti-style Sangiovese or a medium Merlot matches tomato and olive oil richness.",
        "Substitute: medium-bodied red (Merlot / Sangiovese / Cabernet blend), not too oaky.",
    ),
    (
        ["french", "butter", "duck", "bistro"],
        "Unoaked or lightly oaked Chardonnay suits butter sauces; Pinot Noir for duck.",
        "Substitute: white Burgundy style (Chardonnay) or light red (Pinot Noir).",
    ),
    (
        ["asian", "soy", "ginger", "wok", "udon", "ramen"],
        "Aromatic dry white (Riesling / Gruner style) or jasmine green tea if skipping alcohol.",
        "Substitute: dry aromatic white; beer: light lager.",
    ),
    (
        ["japanese", "sushi", "sashimi", "miso", "soy"],
        "Junmai-style sake or a very dry sparkling white keeps the palate clean.",
        "Substitute: dry sparkling white or light lager if sake is unavailable.",
    ),
    (
        ["spanish", "tapas", "paella", "chorizo"],
        "Rioja-style Tempranillo or dry Cava for a festive yacht platter.",
        "Substitute: medium red (Tempranillo / Grenache style) or dry sparkling white.",
    ),
    (
        ["caribbean", "jerk", "rum", "plantain", "coconut"],
        "Ice-cold lager or a rum highball with lime; for wine, off-dry Riesling or rose.",
        "Substitute: any cold lager or dry rose; keep spirits light with plenty of ice and citrus.",
    ),
    (
        ["salad", "fig", "prosciutto", "cheese", "appetizer"],
        "Dry rose or light Pinot Grigio keeps salty cured meat and soft cheese lively.",
        "Substitute: dry rose or crisp light white (Pinot Grigio / Sauvignon Blanc).",
    ),
    (
        ["beef", "lamb", "steak", "wellington"],
        "Cabernet Sauvignon or Shiraz/Syrah stands up to rich beef.",
        "Substitute: full red (Cabernet / Merlot / Shiraz), prefer fruit-forward over heavily oaked if young.",
    ),
    (
        ["pork", "chop", "ham"],
        "Dry Riesling or light Pinot Noir bridges sweet glaze and savoury pork.",
        "Substitute: dry white with some body or light red (Pinot Noir).",
    ),
    (
        ["chicken", "poultry"],
        "Unoaked Chardonnay or light Pinot Noir is a safe deck pairing.",
        "Substitute: medium white (Chardonnay) or light red.",
    ),
]


def slugify(name: str) -> str:
    s = unicodedata.normalize("NFKD", name)
    s = s.encode("ascii", "ignore").decode("ascii")
    s = re.sub(r"[^a-zA-Z0-9]+", "_", s).strip("_").lower()
    return s[:48] or "dish"


def as_list(v) -> list[str]:
    if v is None:
        return []
    if isinstance(v, list):
        return [str(x).strip() for x in v if str(x).strip()]
    if isinstance(v, str) and v.strip():
        return [v.strip()]
    return []


def scale_qty(qty, unit: str | None, course: str) -> float | None:
    """Scale toward a 2-person base. Spices barely scale; bulk proteins do."""
    if qty is None:
        return None
    try:
        q = float(qty)
    except (TypeError, ValueError):
        return None
    u = (unit or "").lower().strip()
    # Tiny measures stay put (after metric conversion, small ml/g)
    if u in ("dash", "pinch", "ml", "g") and q <= 15:
        return round(q, 2) if q % 1 else int(q) if q == int(q) else round(q, 2)
    # Preserves / snacks often already small-batch
    if course in ("preserves", "snack", "appetizer"):
        factor = 1.0
    elif course == "dessert":
        factor = 0.6
    elif course == "side":
        factor = 0.55
    elif course == "breakfast":
        factor = 0.55
    else:
        # mains / braai often written for 4
        factor = 0.5
    out = q * factor
    # Avoid microscopic amounts
    if u in ("kg", "lb") and out < 0.1:
        out = 0.1
    if out >= 10:
        out = round(out, 1)
    elif out >= 1:
        out = round(out, 2)
    else:
        out = round(out, 3)
    if abs(out - round(out)) < 1e-9:
        return int(round(out))
    return out


def _nice(v: float):
    if abs(v - round(v)) < 1e-9:
        return int(round(v))
    if abs(v) >= 10:
        return round(v, 1)
    return round(v, 2)


def convert_imperial_qty(qty, unit: str | None):
    """Store all convertible measures as metric (ml/g). Count units pass through."""
    if qty is None or not unit:
        return qty, unit
    u = unit.lower().strip().replace(".", "")
    try:
        q = float(qty)
    except (TypeError, ValueError):
        return qty, unit
    vol = {
        "tsp": 5,
        "tsps": 5,
        "teaspoon": 5,
        "teaspoons": 5,
        "tbsp": 15,
        "tbsps": 15,
        "tablespoon": 15,
        "tablespoons": 15,
        "cup": 240,
        "cups": 240,
        "oz": 29.5735,  # fluid oz (US culinary / bar)
        "ounce": 29.5735,
        "ounces": 29.5735,
        "fl oz": 29.5735,
        "floz": 29.5735,
        "pint": 473.176,
        "pints": 473.176,
        "quart": 946.353,
        "quarts": 946.353,
        "gallon": 3785.41,
        "gallons": 3785.41,
        "gal": 3785.41,
    }
    weight = {
        "lb": 453.592,
        "lbs": 453.592,
        "pound": 453.592,
        "pounds": 453.592,
    }
    if u in vol:
        return _nice(q * vol[u]), "ml"
    if u in weight:
        return _nice(q * weight[u]), "g"
    if u in ("ml", "g", "kg", "l"):
        return qty, u if u != "l" else "L"
    return qty, unit


def has_ingredient(ings: list[dict], name: str) -> bool:
    n = name.lower()
    for i in ings:
        inn = (i.get("name") or "").lower()
        if n in inn or inn in n:
            return True
    return False


def ensure_prose_ingredients(item: dict, ings: list[dict]) -> list[dict]:
    text = " ".join(
        [
            item.get("name") or "",
            item.get("description") or "",
            item.get("instructions") or "",
        ]
    ).lower()
    out = list(ings)
    for phrase, qty, unit in PROSE_INGREDIENTS:
        if phrase not in text:
            continue
        # avoid adding generic "rice" when "jasmine rice" already present etc.
        if has_ingredient(out, phrase):
            continue
        # special cases
        if phrase in ("wine",) and "wine" in text and has_ingredient(out, "wine"):
            continue
        if phrase == "stock" and (
            has_ingredient(out, "stock") or has_ingredient(out, "broth")
        ):
            continue
        if phrase in ("mushroom", "mushrooms", "duxelles") and has_ingredient(
            out, "mushroom"
        ):
            continue
        display = phrase.title() if phrase not in ("pap",) else "Pap (maize porridge)"
        if phrase == "rocket":
            display = "Arugula"
        if phrase == "proscuitto":
            continue
        out.append(
            {
                "name": display,
                "quantity": qty,
                "unit": unit,
                "isOptional": False,
                "isGarnish": phrase
                in ("arugula", "rocket", "basil", "mint", "parsley", "parmesan"),
            }
        )
    return out


def build_story(item: dict, course: str, cuisine_tags: list[str]) -> str:
    blob = " ".join(
        [
            item.get("name") or "",
            course,
            " ".join(cuisine_tags),
            item.get("description") or "",
        ]
    ).lower()
    primary = (
        "A versatile table wine or cold beer works on board - match weight of the dish "
        "to the drink (lighter food -> lighter drink)."
    )
    sub = (
        "Caribbean substitute: dry white (Sauvignon Blanc / Chardonnay style) with fish and "
        "veg; medium red (Merlot / Cabernet blend) with red meat; cold lager with spice and braai."
    )
    for keys, p, s in PAIRINGS:
        if any(k in blob for k in keys):
            primary, sub = p, s
            break
    name = item.get("name") or "This dish"
    base = (
        f"{name} is scaled for two people at sea - double or triple from the app "
        f"servings control for 4, 6, or more guests. "
    )
    return f"{base}{primary} {sub}"


def process_item(item: dict, index: int) -> dict | None:
    name = (item.get("name") or "").strip()
    if not name:
        return None
    course_raw = (item.get("recipeType") or "main").lower().strip()
    course = course_raw if course_raw in COURSE_LABEL else "main"
    course_label = COURSE_LABEL[course]

    cuisine = as_list(item.get("cuisine"))
    if course_label not in cuisine and course_label.lower() not in [
        c.lower() for c in cuisine
    ]:
        cuisine = [course_label, *cuisine]

    raw_ings = item.get("ingredients") or []
    ings: list[dict] = []
    flavors: list[str] = []
    for raw in raw_ings:
        if not isinstance(raw, dict):
            continue
        iname = (raw.get("name") or "").strip()
        if not iname:
            continue
        qty = raw.get("quantity")
        unit = raw.get("unit")
        qty, unit = convert_imperial_qty(qty, unit)
        qty = scale_qty(qty, unit, course)
        for f in as_list(raw.get("flavorProfiles")):
            if f.lower() not in {x.lower() for x in flavors}:
                flavors.append(f)
        ings.append(
            {
                "name": iname,
                "quantity": qty,
                "unit": unit,
                "substitute": raw.get("substitute"),
                "isOptional": bool(raw.get("isOptional") or False),
                "isGarnish": bool(raw.get("isGarnish") or False),
            }
        )

    ings = ensure_prose_ingredients(item, ings)

    # Clean instructions: strip F imperial bake notes lightly? keep as-is for chef skill.
    instructions = item.get("instructions") or ""
    description = item.get("description") or ""

    # Prefer metric temperature hints if present as F only
    def f_to_c(m):
        f = int(m.group(1))
        c = round((f - 32) * 5 / 9 / 5) * 5  # nearest 5
        return f"{c}C"

    instructions = re.sub(r"(\d{3})F", f_to_c, instructions)

    sid = f"menu_imp_{slugify(name)}"
    if len(sid) < 12:
        sid = f"{sid}_{index}"

    story = build_story(item, course, cuisine)

    cooking = item.get("cookingMethod")
    if not cooking:
        if course == "braai":
            cooking = "Grill"
        elif "no-cook" in (instructions or "").lower() or "no cook" in (
            description or ""
        ).lower():
            cooking = "Raw / No-cook"
        elif "wok" in (instructions or "").lower():
            cooking = "Wok"
        elif "oven" in (instructions or "").lower() or "bake" in (
            instructions or ""
        ).lower():
            cooking = "Oven"
        elif "one-pot" in (instructions or "").lower() or "one pot" in (
            instructions or ""
        ).lower():
            cooking = "One-pot"
        else:
            cooking = "Stovetop"

    return {
        "supabaseId": sid,
        "name": name,
        "description": description,
        "instructions": instructions,
        "recipeType": "menu",
        "course": course_label,
        "cuisine": cuisine,
        "flavorProfiles": flavors[:8],
        "cookingMethod": cooking,
        "prepMinutes": item.get("prepMinutes"),
        "cookMinutes": item.get("cookMinutes"),
        "story": story,
        "ingredients": ings,
    }


def main() -> None:
    raw = json.loads(SRC.read_text(encoding="utf-8"))
    items = raw.get("items") or []
    out_list = []
    seen_ids: set[str] = set()
    for i, item in enumerate(items):
        if not isinstance(item, dict):
            continue
        processed = process_item(item, i)
        if not processed:
            continue
        sid = processed["supabaseId"]
        if sid in seen_ids:
            sid = f"{sid}_{i}"
            processed["supabaseId"] = sid
        seen_ids.add(sid)
        out_list.append(processed)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        json.dumps({"version": 1, "menus": out_list}, indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(out_list)} menus -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
