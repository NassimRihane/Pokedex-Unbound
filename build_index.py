"""
Pokedex Unbound - index builder

Reads every Pokemon file in  Pokedex Unbound/Data/pokemon_data/  and writes a single
lightweight file, pokedex-index.json, in the same folder.

The app reads this index once at launch to get, for every Pokemon, everything the main list
needs (names in 3 languages, types, base stats, generation). It no longer has to decode the
full JSON files (moves, locations...) just to search, filter or sort.

The index name contains no "_" on purpose: the app only treats files named
"<number>_<name>.json" as Pokemon.

Run it after data_fetcher.py and data_searcher.py, or after any manual change to the data.
Only the Python standard library is used.
"""

import json
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.absolute()
DATA_DIR = SCRIPT_DIR / "Pokedex Unbound" / "Data" / "pokemon_data"
INDEX_FILE = DATA_DIR / "pokedex-index.json"

# Fallback when a file has no "generation" field yet
GENERATION_RANGES = [(1, 151), (152, 251), (252, 386), (387, 494), (495, 649), (650, 721), (722, 809), (810, 905)]

STAT_KEYS = {
    "hp": "hp",
    "attack": "attack",
    "defense": "defense",
    "special-attack": "specialAttack",
    "special-defense": "specialDefense",
    "speed": "speed",
}


def generation_from_dex(dex):
    for generation, (low, high) in enumerate(GENERATION_RANGES, start=1):
        if low <= dex <= high:
            return generation
    return 0


def check_app_compatibility(stem, data):
    """Report what would make the app fail to decode the file."""
    problems = []
    for key in ("id", "name", "name-jp", "name-fr", "height", "weight", "abilities", "moves", "sprites", "stats", "types"):
        if data.get(key) is None:
            problems.append(f"missing '{key}'")
    for ability in data.get("abilities") or []:
        if not isinstance(ability.get("ability", {}).get("description"), str):
            problems.append(f"ability '{ability.get('ability', {}).get('name')}' has no description (run data_searcher.py)")
    return problems


def main():
    entries = []
    warnings = []

    for path in sorted(DATA_DIR.glob("*_*.json")):
        stem = path.stem
        dex_part, name = stem.split("_", 1)
        if not dex_part.isdigit():
            continue
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            warnings.append(f"{path.name}: invalid JSON ({e})")
            continue

        for problem in check_app_compatibility(stem, data):
            warnings.append(f"{path.name}: {problem}")

        dex = int(dex_part)
        stats = {key: 0 for key in STAT_KEYS.values()}
        for stat in data.get("stats", []):
            key = STAT_KEYS.get(stat["stat"]["name"])
            if key:
                stats[key] = stat["base_stat"]

        entries.append({
            "file": stem,
            "dex": dex,
            "name": name,
            "nameEn": data.get("name-en") or name.replace("-", " ").title(),
            "nameJp": data.get("name-jp"),
            "nameFr": data.get("name-fr"),
            "generation": data.get("generation") or generation_from_dex(dex),
            "form": data.get("form"),
            "types": [t["type"]["name"] for t in sorted(data.get("types", []), key=lambda t: t["slot"])],
            "stats": stats,
        })

    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, separators=(",", ":"))

    print(f"✓ Index written: {INDEX_FILE.name} ({len(entries)} Pokemon, {INDEX_FILE.stat().st_size // 1024} KB)")
    if warnings:
        print(f"! {len(warnings)} warning(s):")
        for warning in warnings:
            print(f"  - {warning}")


if __name__ == "__main__":
    main()
