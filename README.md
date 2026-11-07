# Pokédex Unbound

**A native iOS Pokédex and capture tracker for the main-series games and the *Pokémon Unbound* fan game. Built with SwiftUI, it works fully offline.**

Pokédex Unbound is a personal companion app for playing through Pokémon games. It brings together the reference data I kept looking up during a run: base stats, moves, evolutions, encounter locations and which Pokémon I have already caught in each game. All of it ships inside the app bundle, so it works anywhere with no network connection.

---

## Features

### Browsing the Pokédex
- **905 Pokémon** from Generation I to VIII, plus **regional forms** (Alolan, Galarian, Hisuian). Each form is a separate entry with its own types, stats, moves and evolutions.
- **Three layouts** (large grid, compact grid, list). Switch between them from the toolbar or with a **pinch gesture** on the list.
- **Multilingual search**: find a Pokémon by its **English**, **French** or **Japanese (romaji)** name, e.g. *Venusaur*, *Florizarre*, *Fushigibana* or *Goupix d'Alola*.
- Official display names (*Mr. Mime*, *Nidoran♀*, *Tapu Koko*, *Alolan Vulpix*…) instead of raw identifiers.

### Filtering and sorting
All of these filters combine with each other:
- **Type**: pick one or two types to find a specific type combination.
- **Generation**: select one or several generations. Regional forms belong to the generation that introduced them, e.g. Alolan forms appear under Generation VII.
- **Minimum base stats**: a slider for each stat (HP, Atk, Def, Sp. Atk, Sp. Def, Speed).
- **Capture status**: caught / not caught, for each game.
- **Sorting** by Pokédex number, name, any single base stat or total base stats, in ascending or descending order.
- A badge counts the active filters, and removable chips show which ones are applied.

### Pokémon pages
Each Pokémon has four tabs:
| Tab | Content |
|---|---|
| **Details** | Sprite, names, types, height/weight, base stats with color-coded bars that show how a stat ranks against all Pokémon, and the **evolution chain** with its conditions (level, item, friendship, time of day, trade…). Tap any stage to open its page |
| **Moves** | Abilities (including hidden ones) and moves learned by level-up and by TM/HM, with type, power, accuracy and PP |
| **Zones** | Encounter locations grouped by generation and version |
| **Capture** | Mark the games where you caught this Pokémon (31 games, Red/Blue to Sword/Shield, plus Unbound). Only games from its debut generation onward are listed |

### Comparison
- A side-by-side screen that compares the base stats of any two Pokémon.

### Persistence
- Capture progress is saved locally to a JSON file in the app's Documents folder. Older data stored in `UserDefaults` is migrated automatically.

---

## Tech stack

- **Swift / SwiftUI**, iOS 26 deployment target
- **MVVM**-style structure with `ObservableObject` view models and environment objects
- **Python 3** data pipeline built on [PokéAPI](https://pokeapi.co/)
- No third-party Swift dependencies

## Project structure

```
Pokedex Unbound/
├── Pokedex_UnboundApp.swift      # App entry point, injects the CaptureManager
├── Models/PokemonModel.swift     # Pokemon (list entry), DetailPokemon (full file), index and evolution models
├── Managers/PokemonManager.swift # Lists the bundled Pokémon files, reads the index
├── ViewModels/ViewModel.swift    # Search, caches for names/types/stats (filled from the index)
├── Helper/Helpers.swift          # Bundle helpers (JSON decoding, image loading)
├── Views/
│   ├── ContentView.swift         # Main grid/list, filters, sorting, pinch gesture
│   ├── PokemonTabView.swift      # Per-Pokémon tab container
│   ├── PokemonDetailView.swift   # Info, stat bars, evolution chain
│   ├── PokemonMovesView.swift    # Abilities and moves by learn method
│   ├── PokemonZonesView.swift    # Encounter locations by generation
│   ├── PokemonCaptureView.swift  # Capture tracker + CaptureManager
│   └── PokemonComparisonView.swift
└── Data/                         # Not versioned, see below
    ├── pokemon_data/             # One JSON per Pokémon + pokedex-index.json
    ├── sprites/                  # One PNG per Pokémon
    ├── types/                    # Type icons
    └── generations/              # Generation badges
data_fetcher.py                   # 1. Base data, sprites, regional forms, evolution chains
data_searcher.py                  # 2. Ability descriptions and encounter locations
build_index.py                    # 3. Lightweight index read by the app at launch
```

### How a Pokémon is identified
Every entry is backed by two files sharing the same base name: `<Pokédex number>_<PokéAPI name>`, e.g. `025_pikachu.json` + `025_pikachu.png`, or `037_vulpix-alola.json` for a regional form. In the code, a `Pokemon` has:
- `fileName`: the unique base name of its files (`037_vulpix-alola`)
- `dexNumber`: its National Pokédex number, shared with the base species for regional forms (`37`)
- `name`: its unique PokéAPI name, also the key of the capture tracker (`vulpix-alola`)
- `displayName`: the name shown in the interface (`Alolan Vulpix`)
- `generation`: the generation that introduced it (`7`)

## Data

Pokémon data and sprites are **not included in this repository**, for copyright and storage reasons. They are generated locally from PokéAPI by three scripts, run in this order from the repository root:

```bash
python3 -m pip install requests   # needed by data_searcher.py only
python3 data_fetcher.py           # base files, sprites, regional forms, evolution chains
python3 data_searcher.py          # ability descriptions, encounter locations
python3 build_index.py            # writes pokedex-index.json
```

- **The scripts only add what is missing.** An existing file is never downloaded again: it only receives the fields it lacks. Adding a new feature to the data therefore does not require downloading everything again, and running a script twice never creates duplicates.
- `data_fetcher.py` caches every PokéAPI response in `.api_cache/` (ignored by Git). Delete that folder to force fresh data.
- Moves come from *Sword/Shield*, falling back to *Ultra Sun/Ultra Moon* for each move the Pokémon cannot learn in *Sword/Shield*.
- `build_index.py` also reports any file the app would fail to decode.
- The app reads `pokedex-index.json` once at launch, which makes searching, filtering and sorting instant. If the index is missing, the app still works and reads the full files instead, which is slower.
- *Pokémon Unbound* encounter locations are not part of this pipeline, since the game is an unofficial fan game. The capture tracker still supports it.

## Building

1. Clone the repository and generate the data (see above).
2. Open `Pokedex Unbound.xcodeproj` in **Xcode**.
3. Select your development team under *Signing & Capabilities*, then build and run on an iPhone or a simulator.

To keep the app on an iPhone without a paid developer account, the app can be exported as an `.ipa` and installed with AltStore, which renews the free 7-day signature from the phone.

## Disclaimer

This is a non-commercial fan project made for personal and educational use. Pokémon and all related names, sprites and data are © Nintendo, Game Freak and The Pokémon Company. *Pokémon Unbound* is a fan game by its respective creators. This project is not affiliated with or endorsed by any of them. Data is provided by [PokéAPI](https://pokeapi.co/).

## Author

Nassim Rihane
