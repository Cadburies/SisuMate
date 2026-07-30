#!/usr/bin/env python3
"""Process cocktails_import.json → assets/seed/cocktails_import_seed.json.

Rules (product):
  - Single-glass servings (scale multi-serve punches down).
  - Metric only: oz → ml snapped to standard bar volumes (no fractions).
  - Skip names already covered by the classic seeder in seed_recipes.dart.
  - Dedupe near-identical name+ingredient variants; keep true variants with
    disambiguated names.
  - Ensure every cocktail has a garnish (from file, instructions, or inference).
  - Prefer concrete descriptions (not fluff).
"""

from __future__ import annotations

import json
import re
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "cocktails_import.json"
OUT = ROOT / "assets" / "seed" / "cocktails_import_seed.json"

SKIP_NAMES = {
    "mai tai",
    "zombie",
    "painkiller",
    "navy grog",
    "suffering bastard",
    "fog cutter",
    "scorpion bowl",
    "three dots and a dash",
    "missionary's downfall",
    "beachbum's own",
    "jet pilot",
    "jungle bird",
    "saturn",
    "test pilot",
    "doctor funk",
    "cobra's fang",
}

# Whole-number bar metric volumes (ml).
STANDARD_ML = [
    5,
    10,
    15,
    20,
    25,
    30,
    40,
    45,
    50,
    60,
    75,
    90,
    100,
    120,
    150,
    180,
    200,
    240,
    300,
]

GARNISH_NAME_HINTS = {
    "fresh mint",
    "mint sprig",
    "lime wheel",
    "lime wedge",
    "lemon wheel",
    "lemon twist",
    "orange twist",
    "orange wheel",
    "maraschino cherry",
    "brandied cherry",
    "pineapple spear",
    "pineapple spears",
    "pineapple wedge",
    "edible orchid",
    "fresh nutmeg",
    "freshly grated nutmeg",
    "apple slice",
    "olive or lemon twist",
    "jalapeño slice",
    "chili salt",
    "fresh pineapple",
    "edible flowers",
    "fruit skewer",
}


def snap_ml(ml: float) -> int:
    if ml <= 0:
        return 5
    return min(STANDARD_ML, key=lambda s: abs(s - ml))


def slug(s: str) -> str:
    s = s.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return s.strip("_")[:60]


def ingredient_sig(ings) -> str:
    parts = []
    for i in ings:
        if i.get("isGarnish"):
            continue
        q = i.get("quantity")
        u = (i.get("unit") or "").lower()
        parts.append(f"{i['name'].lower()}|{q}|{u}")
    return "||".join(sorted(parts))


def liquid_oz(ings) -> float:
    t = 0.0
    for i in ings:
        if i.get("isGarnish"):
            continue
        u = (i.get("unit") or "").lower()
        q = i.get("quantity")
        if u == "oz" and isinstance(q, (int, float)):
            t += float(q)
        elif u == "tsp" and isinstance(q, (int, float)):
            t += float(q) * 0.167
    return t


def extract_garnishes_from_instructions(text: str) -> list[str]:
    if not text:
        return []
    m = re.search(r"[Gg]arnish(?:ed)?(?: with)?[:\s]+(.+?)(?:\.|$)", text)
    if not m:
        return []
    chunk = m.group(1).strip()
    # "extravagantly with fruit and flowers" → fruit + flowers, drop adverb.
    chunk = re.sub(
        r"^(extravagantly|generously|liberally|lightly)\s+(with\s+)?",
        "",
        chunk,
        flags=re.I,
    )
    bits = re.split(r"\s+and\s+|,\s*", chunk)
    out: list[str] = []
    mapping = {
        "mint": "Fresh Mint",
        "mint sprig": "Fresh Mint",
        "lime": "Lime Wheel",
        "lime wheel": "Lime Wheel",
        "lime wedge": "Lime Wedge",
        "lemon": "Lemon Wheel",
        "lemon wheel": "Lemon Wheel",
        "lemon twist": "Lemon Twist",
        "orange": "Orange Wheel",
        "orange wheel": "Orange Wheel",
        "orange twist": "Orange Twist",
        "cherry": "Maraschino Cherry",
        "maraschino cherry": "Maraschino Cherry",
        "pineapple": "Pineapple Spear",
        "pineapple spear": "Pineapple Spear",
        "pineapple wedge": "Pineapple Wedge",
        "fruit": "Pineapple Spear",
        "fruits": "Pineapple Spear",
        "flowers": "Edible Flowers",
        "edible flowers": "Edible Flowers",
        "orchid": "Edible Orchid",
        "nutmeg": "Freshly Grated Nutmeg",
        "freshly grated nutmeg": "Freshly Grated Nutmeg",
        "paper umbrella": None,
        "umbrella": None,
    }
    for b in bits:
        b = b.strip().strip(".").strip()
        b = re.sub(r"^(a|an|the|fresh|some|with)\s+", "", b, flags=re.I).strip()
        if not b or len(b) > 40:
            continue
        # Skip pure adverbs leftover
        if b.lower() in {"extravagantly", "generously", "liberally", "lightly"}:
            continue
        low = b.lower()
        if low in mapping:
            mapped = mapping[low]
            if mapped:
                out.append(mapped)
            continue
        name = " ".join(w.capitalize() if w.islower() else w for w in b.split())
        out.append(name)
    return out


def infer_garnish(recipe) -> list[tuple[str, str]]:
    ings = recipe["ingredients"]
    names = " ".join(i["name"].lower() for i in ings if not i.get("isGarnish"))
    cuisines = [c.lower() for c in recipe.get("cuisine") or []]
    flavors = [f.lower() for f in recipe.get("flavorProfiles") or []]
    glass = (recipe.get("glasstype") or recipe.get("glassware") or "").lower()
    rname = recipe["name"].lower()

    if "tiki" in cuisines or "tropical" in flavors:
        return [
            (
                "Fresh Mint",
                "Slap a sprig and plant it in the ice so the aroma hits first.",
            )
        ]
    if (
        "campari" in names
        or "negroni" in rname
        or "americano" in rname
        or "boulevardier" in rname
    ):
        return [
            (
                "Orange Twist",
                "Express oils over the drink and drop in or rest on the rim.",
            )
        ]
    if "lime" in names:
        return [
            (
                "Lime Wheel",
                "Nick the rind and perch on the rim; squeeze lightly before placing.",
            )
        ]
    if "lemon" in names:
        return [
            (
                "Lemon Twist",
                "Express oils over the surface and rest on the rim.",
            )
        ]
    if "orange" in names:
        return [
            ("Orange Twist", "Express oils over the drink and drop in.")
        ]
    if any(w in names for w in ("whiskey", "bourbon", "rye", "scotch")):
        return [
            (
                "Maraschino Cherry",
                "Skewer or drop a quality cherry into the glass.",
            )
        ]
    if any(w in names for w in ("cream", "cacao", "chocolate", "menthe")):
        return [
            (
                "Maraschino Cherry",
                "Drop a cherry into the glass for colour and aroma.",
            )
        ]
    if "gin" in names:
        return [
            (
                "Lemon Twist",
                "Express oils over the drink and rest on the rim.",
            )
        ]
    if "tequila" in names or "mezcal" in names:
        return [("Lime Wheel", "Perch a thin wheel on the rim.")]
    if "coupe" in glass:
        return [
            (
                "Lemon Twist",
                "Express oils over the drink and rest on the rim.",
            )
        ]
    return [("Lime Wheel", "Perch a thin wheel on the rim as a bright finish.")]


def improve_description(recipe) -> str:
    desc = (recipe.get("description") or "").strip()
    ings = [i["name"] for i in recipe["ingredients"] if not i.get("isGarnish")]
    spirits = ings[:3]
    generic = (
        len(desc) < 28
        or re.search(
            r"\b(nice|delicious|tasty|amazing|great)\s+cocktail\b", desc, re.I
        )
        or desc.lower()
        in {"a cocktail", "cocktail", "a classic cocktail", "it is a nice cocktail"}
    )
    if not generic and desc:
        return desc
    cuisine = recipe.get("cuisine") or []
    flavors = recipe.get("flavorProfiles") or []
    style = cuisine[0] if cuisine else (flavors[0] if flavors else "")
    base = ", ".join(spirits[:3]) if spirits else "spirit"
    if style:
        return f"{style} cocktail built on {base}."
    return f"Built on {base}."


def default_glassware(recipe, scaled: bool) -> str | None:
    glass = recipe.get("glasstype") or recipe.get("glassware")
    if glass and "bowl" in glass.lower() and scaled:
        return "Tall glass"
    if glass:
        return glass
    names = " ".join(
        i["name"].lower()
        for i in recipe.get("ingredients") or []
        if not i.get("isGarnish")
    )
    cuisines = [c.lower() for c in recipe.get("cuisine") or []]
    rname = recipe["name"].lower()
    if scaled or "punch" in rname or "tiki" in cuisines:
        return "Tall glass"
    if any(w in names for w in ("campari", "vermouth")) and "soda" not in names:
        return "Rocks glass"
    if "champagne" in names or "sparkling" in names:
        return "Flute"
    if "cream" in names or "cacao" in names:
        return "Coupe"
    if any(w in names for w in ("whiskey", "bourbon", "rye", "cognac")):
        return "Coupe"
    if "soda" in names or "ginger beer" in names:
        return "Highball glass"
    return "Rocks glass"


def convert_ingredient(ing, scale: float) -> dict:
    name = ing["name"].strip()
    is_g = bool(ing.get("isGarnish"))
    unit = (ing.get("unit") or "").lower().strip() if ing.get("unit") else None
    qty = ing.get("quantity")

    if name.lower() in GARNISH_NAME_HINTS:
        is_g = True

    if is_g:
        return {
            "name": name,
            "quantity": None,
            "unit": None,
            "isGarnish": True,
            "garnishNotes": None,
        }

    if unit in ("dash", "dashes"):
        q = int(round(float(qty))) if qty is not None else 1
        if q < 1:
            q = 1
        return {
            "name": name,
            "quantity": q,
            "unit": "dash",
            "isGarnish": False,
        }

    if unit == "tsp" and qty is not None:
        ml = snap_ml(float(qty) * 5.0 * scale)
        return {"name": name, "quantity": ml, "unit": "ml", "isGarnish": False}

    if unit == "oz" and qty is not None:
        ml = snap_ml(float(qty) * 30.0 * scale)
        return {"name": name, "quantity": ml, "unit": "ml", "isGarnish": False}

    if unit in ("each", "pieces", "whole") or qty is None:
        if any(
            w in name.lower()
            for w in (
                "mint",
                "lime",
                "lemon",
                "orange",
                "cherry",
                "pineapple",
                "nutmeg",
                "peel",
                "twist",
                "wheel",
                "wedge",
                "sprig",
                "flower",
            )
        ):
            return {
                "name": name,
                "quantity": None,
                "unit": None,
                "isGarnish": True,
            }
        return {
            "name": name,
            "quantity": int(qty) if qty else 1,
            "unit": "piece",
            "isGarnish": False,
        }

    if qty is not None and unit:
        return {
            "name": name,
            "quantity": float(qty) * scale if scale != 1 else float(qty),
            "unit": unit,
            "isGarnish": False,
        }
    return {
        "name": name,
        "quantity": None,
        "unit": None,
        "isGarnish": is_g,
    }


# Liquid toppers mentioned in instructions → default metric amounts on the recipe.
TOPPER_DEFAULTS = {
    "soda": ("Soda Water", 60, "ml"),
    "soda water": ("Soda Water", 60, "ml"),
    "sparkling water": ("Sparkling Water", 60, "ml"),
    "ginger beer": ("Ginger Beer", 90, "ml"),
    "champagne": ("Champagne", 90, "ml"),
    "prosecco": ("Prosecco", 90, "ml"),
    "grapefruit soda": ("Grapefruit Soda", 90, "ml"),
    "hot water": ("Hot Water", 90, "ml"),
    "chilled white wine": ("Chilled White Wine", 90, "ml"),
}


def strip_measures_from_prose(text: str | None) -> str | None:
    """Remove drink measures from instructions/description/story.

    Quantities live on ingredients; prose should say "Top with soda water",
    not "Top with 60 ml soda water".
    """
    if not text:
        return text
    t = text
    # "Top with 60 ml soda water" / "float 15 ml absinthe"
    t = re.sub(
        r"(?i)\b(top with|float|finish with|add)\s+\d+(?:\.\d+)?\s*(?:ml|oz)\s+(?:of\s+)?",
        r"\1 ",
        t,
    )
    t = re.sub(
        r"(?i)\b(top with|float|finish with|add)\s+\d+\s*dash(?:es)?\s+(?:of\s+)?",
        r"\1 ",
        t,
    )
    # "1 cup crushed ice" → "crushed ice" (ice is technique, not a measured ingredient)
    t = re.sub(r"(?i)\b\d+(?:\.\d+)?\s*cups?\s+(crushed ice|ice)\b", r"\1", t)
    # Stray leftover measures like "60 ml of gin" in prose
    t = re.sub(r"(?i)\b\d+(?:\.\d+)?\s*(?:ml|oz)\s+(?:of\s+)?", "", t)
    t = re.sub(r"\s{2,}", " ", t).strip()
    return t


def promote_toppers_to_ingredients(
    ingredients: list[dict], instructions: str | None
) -> tuple[list[dict], str | None]:
    """Ensure 'Top with X' liquids exist as measured ingredients; keep prose bare."""
    if not instructions:
        return ingredients, instructions

    names = {i["name"].lower() for i in ingredients}
    optional = "if desired" in instructions.lower()

    def has_name(target: str) -> bool:
        t = target.lower()
        return any(t in n or n in t for n in names)

    for m in re.finditer(r"(?i)top with ([^.;]+)", instructions):
        top = m.group(1).strip()
        top = re.sub(r"(?i)\s+if desired.*$", "", top).strip()
        top = re.sub(r"(?i)^(a|an|the)\s+", "", top)
        top_key = top.lower()
        if has_name(top_key) or any(
            w in n for n in names for w in top_key.split() if len(w) > 3
        ):
            continue
        default = TOPPER_DEFAULTS.get(top_key)
        if default is None and "soda" in top_key:
            default = TOPPER_DEFAULTS["soda water"]
        if default is None:
            continue
        name, qty, unit = default
        if name.lower() in names:
            continue
        g_idx = next(
            (i for i, x in enumerate(ingredients) if x.get("isGarnish")),
            len(ingredients),
        )
        ingredients.insert(
            g_idx,
            {
                "name": name,
                "quantity": qty,
                "unit": unit,
                "isGarnish": False,
                "isOptional": optional or "if desired" in m.group(0).lower(),
                "sortOrder": g_idx,
            },
        )
        names.add(name.lower())

    for idx, ing in enumerate(ingredients):
        ing["sortOrder"] = idx

    # Normalize "top with soda" → "top with soda water"
    instructions = re.sub(
        r"(?i)top with soda(\s+if desired)?",
        lambda mm: "Top with soda water"
        + (" if desired" if mm.group(1) else ""),
        instructions,
    )
    return ingredients, instructions


def disambiguate_name(name: str, desc: str, story: str, used_names: set[str]) -> str:
    if name not in used_names:
        # Prefer source-tagged names for known dual classics.
        blob = f"{desc} {story}".lower()
        if "trader vic" in blob and name == "Singapore Sling":
            cand = "Singapore Sling (Trader Vic)"
            if cand not in used_names:
                return cand
        if "raffles" in blob and name == "Singapore Sling":
            cand = "Singapore Sling (Raffles)"
            if cand not in used_names:
                return cand
        return name

    blob = f"{desc} {story}".lower()
    for s in (
        " (Trader Vic)",
        " (Raffles)",
        " (Savoy)",
        " (with egg white)",
        " (Tiki)",
        " (IBA)",
    ):
        # only attach if cue matches
        cue = s.strip(" ()").lower()
        if cue == "with egg white":
            if "egg white" not in blob:
                continue
        elif cue not in blob and cue not in desc.lower():
            continue
        cand = name + s
        if cand not in used_names:
            return cand

    n = 2
    while f"{name} (variant {n})" in used_names:
        n += 1
    return f"{name} (variant {n})"


def main() -> None:
    raw = json.loads(SRC.read_text())["items"]

    best: OrderedDict[tuple[str, str], dict] = OrderedDict()
    for it in raw:
        name = it["name"].strip()
        if name.lower() in SKIP_NAMES:
            continue
        sig = ingredient_sig(it.get("ingredients") or [])
        key = (name.lower(), sig)
        prev = best.get(key)
        if prev is None:
            best[key] = it
            continue
        score = lambda r: (
            len(r.get("story") or "")
            + len(r.get("description") or "")
            + len(r.get("ingredients") or [])
        )
        if score(it) > score(prev):
            best[key] = it

    used_names: set[str] = set()
    out_items: list[dict] = []

    for _key, it in best.items():
        desc = improve_description(it)
        story = (it.get("story") or "").strip() or None
        name = disambiguate_name(it["name"].strip(), desc, story or "", used_names)
        used_names.add(name)

        ings_raw = list(it.get("ingredients") or [])
        total_oz = liquid_oz(ings_raw)
        scale = 1.0
        if total_oz > 6.5:
            scale = 5.5 / total_oz

        converted = [convert_ingredient(ing, scale) for ing in ings_raw]

        if not any(c.get("isGarnish") for c in converted):
            from_instr = extract_garnishes_from_instructions(it.get("instructions") or "")
            if from_instr:
                for gname in from_instr:
                    converted.append(
                        {
                            "name": gname,
                            "quantity": None,
                            "unit": None,
                            "isGarnish": True,
                            "garnishNotes": None,
                        }
                    )
            else:
                for gname, notes in infer_garnish(it):
                    converted.append(
                        {
                            "name": gname,
                            "quantity": None,
                            "unit": None,
                            "isGarnish": True,
                            "garnishNotes": notes,
                        }
                    )

        seen_ing: set[str] = set()
        final_ings: list[dict] = []
        for c in converted:
            k = c["name"].lower()
            if k in seen_ing:
                continue
            seen_ing.add(k)
            final_ings.append(c)
        for idx, c in enumerate(final_ings):
            c["sortOrder"] = idx

        glass = default_glassware(it, scale < 1.0)
        instructions = (it.get("instructions") or "").strip()
        if scale < 1.0:
            instructions = re.sub(
                r"(?i)large bowl|communal bowl|punch bowl",
                "tall glass",
                instructions,
            )
            if "single serving" not in instructions.lower() and "one glass" not in instructions.lower():
                instructions = (
                    instructions.rstrip(".") + ". Recipe scaled to one glass."
                )

        # Quantities belong on ingredients, not in prose.
        # "Top with 60 ml soda water" → ingredient + "Top with soda water".
        final_ings, instructions = promote_toppers_to_ingredients(
            final_ings, instructions
        )
        instructions = strip_measures_from_prose(instructions)
        desc = strip_measures_from_prose(desc)
        if story:
            story = strip_measures_from_prose(story)

        prep = it.get("prepMinutes")
        if isinstance(prep, float):
            prep = int(prep)
        if not isinstance(prep, int):
            prep = None

        sid = f"cocktail_imp_{slug(name)}"
        base_sid = sid
        n = 2
        existing_ids = {x["supabaseId"] for x in out_items}
        while sid in existing_ids:
            sid = f"{base_sid}_{n}"
            n += 1

        out_items.append(
            {
                "supabaseId": sid,
                "name": name,
                "description": desc,
                "instructions": instructions or None,
                "recipeType": "cocktail",
                "glassware": glass,
                "prepMinutes": prep,
                "story": story,
                "cuisine": it.get("cuisine") or [],
                "flavorProfiles": it.get("flavorProfiles") or [],
                "ingredients": final_ings,
            }
        )

    problems = []
    for r in out_items:
        if not any(i.get("isGarnish") for i in r["ingredients"]):
            problems.append((r["name"], "no garnish"))
        for i in r["ingredients"]:
            if i.get("unit") == "oz":
                problems.append((r["name"], i["name"], "still oz"))
            q = i.get("quantity")
            if isinstance(q, float) and not q.is_integer():
                problems.append((r["name"], i["name"], f"fraction {q}"))
            if i.get("unit") == "ml" and q is not None and int(q) not in STANDARD_ML:
                problems.append((r["name"], i["name"], f"nonstandard ml {q}"))
            if i.get("isGarnish") and (
                "extravagant" in i["name"].lower() or i["name"].lower() == "flowers"
            ):
                problems.append((r["name"], i["name"], "bad garnish parse"))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        json.dumps({"version": 1, "cocktails": out_items}, indent=2, ensure_ascii=False)
        + "\n"
    )
    print(f"wrote {OUT} — {len(out_items)} cocktails, {len(problems)} problems")
    for p in problems[:20]:
        print(" ", p)
    if problems:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
