"""
Pokedex Unbound - base data fetcher (PokeAPI)

Creates and completes the local data used by the app:
  - one JSON file per Pokemon in  Pokedex Unbound/Data/pokemon_data/  (e.g. 025_pikachu.json)
  - one sprite per Pokemon in      Pokedex Unbound/Data/sprites/       (e.g. 025_pikachu.png)
  - regional forms (Alola, Galar, Hisui) as separate entries           (e.g. 037_vulpix-alola.json)
  - the evolution chain of every Pokemon

Like data_searcher.py, this script only ADDS what is missing: an existing file is never
re-downloaded, it only receives the fields it does not have yet. Re-running the script is
therefore cheap and never creates duplicates.

Every PokeAPI response is cached in .api_cache/ (next to this script) so that a second run
does not hit the network again. Delete that folder to force fresh data.

Order of the data pipeline:
  1. python3 data_fetcher.py    (this file: base files, sprites, forms, evolutions)
  2. python3 data_searcher.py   (ability descriptions + encounter locations)
  3. python3 build_index.py     (lightweight index read by the app at launch)

Only the Python standard library is used.
"""

import json
import re
import time
import urllib.request
import urllib.error
from collections import defaultdict
from pathlib import Path

# === Configuration ===
SCRIPT_DIR = Path(__file__).parent.absolute()
DATA_DIR = SCRIPT_DIR / "Pokedex Unbound" / "Data" / "pokemon_data"
SPRITES_DIR = SCRIPT_DIR / "Pokedex Unbound" / "Data" / "sprites"
CACHE_DIR = SCRIPT_DIR / ".api_cache"

API = "https://pokeapi.co/api/v2"
START_ID = 1
MAX_ID = 905  # Generation I to VIII

# Moves: for each move, keep the entries of the first version group (in this order) where the
# Pokemon learns it by level-up or TM/HM. This is the rule used to build the original files.
MOVE_VERSION_GROUPS = ["sword-shield", "ultra-sun-ultra-moon"]
# Used only when the rule above gives no move at all (Pokemon only available in Legends: Arceus)
MOVE_FALLBACK_VERSION_GROUPS = ["legends-arceus"]
MOVE_METHODS = ("level-up", "machine")

# Regional forms kept as separate entries, with the generation that introduced them
REGIONS = {"alola": 7, "galar": 8, "hisui": 8}
REGION_ADJECTIVE_EN = {"alola": "Alolan", "galar": "Galarian", "hisui": "Hisuian"}
REGION_SUFFIX_FR = {"alola": "d'Alola", "galar": "de Galar", "hisui": "de Hisui"}
# e.g. vulpix-alola, meowth-galar, darmanitan-galar-standard (but not darmanitan-galar-zen)
REGIONAL_FORM_PATTERN = re.compile(r"^[a-z0-9-]+?-(alola|galar|hisui)(-standard)?$")
EXCLUDED_FORM_WORDS = ("totem", "cap", "gmax")
OTHER_REGION_WORDS = ("alola", "galar", "hisui", "paldea")

# Evolution methods introduced after Generation VIII are ignored
EXCLUDED_EVOLUTION_VERSION_GROUPS = {"scarlet-violet", "the-teal-mask", "the-indigo-disk", "legends-za", "mega-dimension"}

GENERATION_NUMBERS = {
    "generation-i": 1, "generation-ii": 2, "generation-iii": 3, "generation-iv": 4,
    "generation-v": 5, "generation-vi": 6, "generation-vii": 7, "generation-viii": 8,
    "generation-ix": 9,
}


# === Network helpers ===

def _cache_path(url):
    key = url.replace(API, "").strip("/").replace("/", "_") or "root"
    return CACHE_DIR / f"{key}.json"


def get_json(url):
    """GET a PokeAPI resource, using the local cache when possible."""
    cache_file = _cache_path(url)
    if cache_file.exists():
        with open(cache_file, "r", encoding="utf-8") as f:
            return json.load(f)

    for attempt in range(4):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "pokedex-unbound-data-fetcher"})
            with urllib.request.urlopen(request, timeout=30) as response:
                data = json.loads(response.read().decode("utf-8"))
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            with open(cache_file, "w", encoding="utf-8") as f:
                json.dump(data, f)
            time.sleep(0.05)  # be gentle with the API
            return data
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            print(f"    ! HTTP {e.code} for {url}, retrying...")
        except Exception as e:
            print(f"    ! {e} for {url}, retrying...")
        time.sleep(1 + attempt * 2)
    raise RuntimeError(f"Could not fetch {url}")


def download_file(url, destination):
    request = urllib.request.Request(url, headers={"User-Agent": "pokedex-unbound-data-fetcher"})
    with urllib.request.urlopen(request, timeout=30) as response:
        destination.write_bytes(response.read())


def id_from_url(url):
    return int(url.rstrip("/").split("/")[-1])


# === Text helpers ===

def clean_text(text):
    """Use straight apostrophes so that search works with a regular keyboard."""
    return text.replace("’", "'") if text else text


def localized_name(species, language):
    for entry in species["names"]:
        if entry["language"]["name"] == language:
            return clean_text(entry["name"])
    return None


def pretty(slug):
    """'fire-stone' -> 'Fire Stone'"""
    return slug.replace("-", " ").title() if slug else ""


def region_of(pokemon_name):
    match = REGIONAL_FORM_PATTERN.match(pokemon_name)
    return match.group(1) if match else None


def is_regional_form(pokemon_name):
    return region_of(pokemon_name) is not None and not any(w in pokemon_name.split("-") for w in EXCLUDED_FORM_WORDS)


# === Building one Pokemon entry ===

def get_ability_description(ability_url):
    """Latest English flavor text of an ability (same logic as data_searcher.py)."""
    ability = get_json(ability_url) or {}
    english = [e["flavor_text"] for e in ability.get("flavor_text_entries", []) if e["language"]["name"] == "en"]
    if english:
        return english[-1].replace("\n", " ").replace("\f", " ")
    return ""


def build_abilities(pokemon):
    return [
        {
            "ability": {
                "name": a["ability"]["name"],
                "url": a["ability"]["url"],
                "description": get_ability_description(a["ability"]["url"]),
            },
            "is_hidden": a["is_hidden"],
            "slot": a["slot"],
        }
        for a in pokemon["abilities"]
    ]


def get_move_details(move_name):
    move = get_json(f"{API}/move/{move_name}/") or {}
    return {
        "name": move_name,
        "type": (move.get("type") or {}).get("name"),
        "power": move.get("power"),
        "pp": move.get("pp"),
        "accuracy": move.get("accuracy"),
    }


def build_moves(pokemon, version_groups):
    moves = []
    for entry in pokemon["moves"]:
        details = entry["version_group_details"]
        for group in version_groups:
            selected = [
                d for d in details
                if d["version_group"]["name"] == group and d["move_learn_method"]["name"] in MOVE_METHODS
            ]
            if selected:
                move_details = get_move_details(entry["move"]["name"])
                for d in selected:
                    moves.append({
                        "move": move_details,
                        "level_learned_at": d["level_learned_at"],
                        "move_learn_method": d["move_learn_method"]["name"],
                        "version_group": group,
                    })
                break
    return moves


def select_moves(pokemon):
    return build_moves(pokemon, MOVE_VERSION_GROUPS) or build_moves(pokemon, MOVE_FALLBACK_VERSION_GROUPS)


def sprite_url(pokemon):
    sprites = pokemon.get("sprites") or {}
    other = sprites.get("other") or {}
    return (
        sprites.get("front_default")
        or (other.get("home") or {}).get("front_default")
        or (other.get("official-artwork") or {}).get("front_default")
    )


def display_names(species, region):
    """English / French / Japanese (romaji) names, with the region for regional forms."""
    en = localized_name(species, "en") or pretty(species["name"])
    fr = localized_name(species, "fr") or en
    jp = localized_name(species, "ja-roma") or localized_name(species, "roomaji") or en
    if region:
        en = f"{REGION_ADJECTIVE_EN[region]} {en}"
        fr = f"{fr} {REGION_SUFFIX_FR[region]}"
    return en, fr, jp


def build_entry(pokemon, species, region):
    en, fr, jp = display_names(species, region)
    generation = REGIONS[region] if region else GENERATION_NUMBERS.get(species["generation"]["name"], 0)
    return {
        "id": pokemon["id"],
        "name": pokemon["name"],
        "name-jp": jp,
        "name-fr": fr,
        "name-en": en,
        "dex": species["id"],
        "generation": generation,
        "form": region,
        "height": pokemon["height"],
        "weight": pokemon["weight"],
        "abilities": build_abilities(pokemon),
        "moves": select_moves(pokemon),
        "sprites": {"front_default": sprite_url(pokemon)},
        "stats": [
            {"base_stat": s["base_stat"], "effort": s["effort"], "stat": s["stat"]} for s in pokemon["stats"]
        ],
        "types": [{"slot": t["slot"], "type": t["type"]} for t in pokemon["types"]],
    }


# === Files ===

def file_stem(dex, pokemon_name):
    return f"{dex:03d}_{pokemon_name}"


def load(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def ensure_sprite(stem, pokemon):
    destination = SPRITES_DIR / f"{stem}.png"
    if destination.exists():
        return
    url = sprite_url(pokemon)
    if not url:
        print(f"    ! No sprite available for {stem}")
        return
    try:
        download_file(url, destination)
        print(f"    + Sprite downloaded")
    except Exception as e:
        print(f"    ! Sprite download failed for {stem}: {e}")


def create_or_complete(dex, pokemon_name, species, region):
    """Create the file of one Pokemon, or add the fields an existing file is missing."""
    stem = file_stem(dex, pokemon_name)
    path = DATA_DIR / f"{stem}.json"
    if not path.exists() and region is None:
        # Reuse an existing file of this species saved under another name, to avoid duplicates
        existing = [p for p in DATA_DIR.glob(f"{dex:03d}_*.json") if not is_regional_form(p.stem.split("_", 1)[1])]
        if existing:
            path, stem = existing[0], existing[0].stem
    pokemon = get_json(f"{API}/pokemon/{pokemon_name}/")
    if pokemon is None:
        print(f"  ! {pokemon_name} not found on PokeAPI")
        return None

    if not path.exists():
        print(f"  + Creating {stem}.json")
        save(path, build_entry(pokemon, species, region))
    else:
        data = load(path)
        en, fr, jp = display_names(species, region)
        missing = {
            "name-en": en,
            "dex": dex,
            "generation": REGIONS[region] if region else GENERATION_NUMBERS.get(species["generation"]["name"], 0),
            "form": region,
        }
        modified = False
        for key, value in missing.items():
            if key not in data:
                data[key] = value
                modified = True
        if not data.get("moves"):
            moves = select_moves(pokemon)
            if moves:
                data["moves"] = moves
                modified = True
        if modified:
            save(path, data)
            print(f"  ~ Completed {stem}.json")

    ensure_sprite(stem, pokemon)
    return stem


# === Evolution chains ===

def evolution_condition(detail):
    """Turn one PokeAPI evolution_details entry into a short English sentence."""
    trigger = (detail.get("trigger") or {}).get("name", "")
    name = lambda key: pretty((detail.get(key) or {}).get("name"))
    parts = []

    if trigger == "level-up":
        parts.append(f"Level {detail['min_level']}" if detail.get("min_level") else "Level up")
    elif trigger == "use-item":
        parts.append(f"Use {name('item')}")
    elif trigger == "trade":
        parts.append("Trade")
    elif trigger == "shed":
        parts.append("Level 20 with an empty slot and a Poke Ball")
    elif trigger == "spin":
        parts.append("Spin around holding a Sweet")
    elif trigger == "tower-of-darkness":
        parts.append("Tower of Darkness")
    elif trigger == "tower-of-waters":
        parts.append("Tower of Waters")
    elif trigger == "three-critical-hits":
        parts.append("Land 3 critical hits in one battle")
    elif trigger == "take-damage":
        parts.append("Take 49+ damage, then walk under the stone arch")
    elif trigger == "agile-style-move":
        parts.append(f"Use {name('known_move')} in Agile Style 20 times")
    elif trigger == "strong-style-move":
        parts.append(f"Use {name('known_move')} in Strong Style 20 times")
    elif trigger == "recoil-damage":
        parts.append("Lose 294+ HP from recoil")
    elif trigger:
        parts.append(pretty(trigger))

    if detail.get("held_item"):
        parts.append(f"holding {name('held_item')}")
    if detail.get("trade_species"):
        parts.append(f"for {name('trade_species')}")
    if detail.get("min_happiness"):
        parts.append("with high Friendship")
    if detail.get("min_affection"):
        parts.append("with high Affection")
    if detail.get("min_beauty"):
        parts.append("with high Beauty")
    if detail.get("known_move") and trigger not in ("agile-style-move", "strong-style-move"):
        parts.append(f"knowing {name('known_move')}")
    if detail.get("known_move_type"):
        parts.append(f"knowing a {name('known_move_type')}-type move")
    if detail.get("location"):
        parts.append(f"at {name('location')}")
    if detail.get("party_species"):
        parts.append(f"with {name('party_species')} in the party")
    if detail.get("party_type"):
        parts.append(f"with a {name('party_type')}-type in the party")
    stats = detail.get("relative_physical_stats")
    if stats is not None:
        parts.append({1: "(Atk > Def)", -1: "(Atk < Def)", 0: "(Atk = Def)"}.get(stats, ""))
    if detail.get("gender") is not None:
        parts.append("(female)" if detail["gender"] == 1 else "(male)")
    if detail.get("time_of_day"):
        parts.append(f"({detail['time_of_day']})")
    if detail.get("needs_overworld_rain"):
        parts.append("while raining")
    if detail.get("turn_upside_down"):
        parts.append("with the console upside down")
    if detail.get("region"):
        parts.append(f"in {name('region')}")

    return " ".join(parts)


def build_evolutions(known):
    """
    known: {pokemon_name: (stem, dex)} for every local file.
    Adds an "evolution_chain" field to every file: the evolution tree(s) the Pokemon belongs to.
    Regional forms get their own tree (e.g. meowth-galar -> perrserker) thanks to the
    required_pokemon_form / evolved_pokemon_form fields of PokeAPI.
    """
    print()
    print("Building evolution chains...")
    species_cache = {}

    def species(species_id):
        if species_id not in species_cache:
            species_cache[species_id] = get_json(f"{API}/pokemon-species/{species_id}/")
        return species_cache[species_id]

    def default_pokemon(species_id):
        for variety in species(species_id)["varieties"]:
            if variety["is_default"]:
                return variety["pokemon"]["name"]
        return None

    def resolve(form, species_id):
        """Pokemon name for a pokemon-form name (None = default form of the species)."""
        if form is None:
            return default_pokemon(species_id)
        form_name = form["name"]
        if form_name in known:
            return form_name
        if any(word in form_name.split("-") for word in OTHER_REGION_WORDS):
            return None  # a regional form we do not keep (e.g. Paldea)
        return default_pokemon(species_id)

    chain_urls = set()
    for name, (stem, dex) in known.items():
        chain = species(dex).get("evolution_chain")
        if chain:
            chain_urls.add(chain["url"])

    edges = defaultdict(list)  # (from, to) -> [conditions]

    def walk(node):
        parent_id = id_from_url(node["species"]["url"])
        for child in node["evolves_to"]:
            child_id = id_from_url(child["species"]["url"])
            if parent_id <= MAX_ID and child_id <= MAX_ID:
                for detail in child["evolution_details"]:
                    group = (detail.get("version_group") or {}).get("name")
                    if group in EXCLUDED_EVOLUTION_VERSION_GROUPS:
                        continue
                    source = resolve(detail.get("required_pokemon_form"), parent_id)
                    target = resolve(detail.get("evolved_pokemon_form"), child_id)
                    if source in known and target in known:
                        condition = evolution_condition(detail)
                        if condition and condition not in edges[(source, target)]:
                            edges[(source, target)].append(condition)
                        elif not condition:
                            edges[(source, target)]
            walk(child)

    for url in sorted(chain_urls):
        walk(get_json(url)["chain"])

    children = defaultdict(list)
    has_parent = set()
    neighbours = defaultdict(set)
    for (source, target) in edges:
        children[source].append(target)
        has_parent.add(target)
        neighbours[source].add(target)
        neighbours[target].add(source)

    def join_conditions(conditions):
        """Several 'Level up at <place>' (one per game) become a single short condition."""
        locations = [c for c in conditions if c.startswith("Level up at ")]
        if len(locations) > 1:
            first = conditions.index(locations[0])
            conditions = [c for c in conditions if c not in locations]
            conditions.insert(first, "Level up at a special location")
        return " / ".join(conditions)

    def sort_key(name):
        return (known[name][1], name)

    def tree(name, condition, seen):
        seen.add(name)
        stem, dex = known[name]
        return {
            "name": name,
            "file": stem,
            "dex": dex,
            "condition": condition,
            "evolves_to": [
                tree(child, join_conditions(edges[(name, child)]), seen)
                for child in sorted(children[name], key=sort_key) if child not in seen
            ],
        }

    updated = 0
    done = set()
    for name in sorted(known, key=sort_key):
        if name in done:
            continue
        # Connected component of this Pokemon
        component, stack = set(), [name]
        while stack:
            current = stack.pop()
            if current not in component:
                component.add(current)
                stack.extend(neighbours[current])
        done |= component

        roots = sorted((n for n in component if n not in has_parent), key=sort_key)
        forest = [tree(root, None, set()) for root in roots] if len(component) > 1 else []

        for member in component:
            path = DATA_DIR / f"{known[member][0]}.json"
            data = load(path)
            if data.get("evolution_chain") != forest:
                data["evolution_chain"] = forest
                save(path, data)
                updated += 1

    print(f"✓ Evolution chains written ({updated} files updated)")


# === Main ===

if __name__ == "__main__":
    print("=" * 60)
    print("POKEMON DATA FETCHER")
    print("=" * 60)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    SPRITES_DIR.mkdir(parents=True, exist_ok=True)

    known = {}  # pokemon name -> (file stem, dex number)
    errors = 0

    for dex in range(START_ID, MAX_ID + 1):
        try:
            species = get_json(f"{API}/pokemon-species/{dex}/")
            print(f"#{dex:03d} {species['name']}")
            for variety in species["varieties"]:
                pokemon_name = variety["pokemon"]["name"]
                if variety["is_default"]:
                    region = None
                elif is_regional_form(pokemon_name):
                    region = region_of(pokemon_name)
                else:
                    continue
                stem = create_or_complete(dex, pokemon_name, species, region)
                if stem:
                    known[pokemon_name] = (stem, dex)
        except Exception as e:
            print(f"  x Error for #{dex}: {e}")
            errors += 1

    build_evolutions(known)

    print("-" * 60)
    print(f"✓ FETCH FINISHED: {len(known)} Pokemon, {errors} errors")
    print("Next steps: python3 data_searcher.py, then python3 build_index.py")
