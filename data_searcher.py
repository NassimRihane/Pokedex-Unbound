import requests
import json
import os
import time

# === Configuration ===
OUTPUT_DIR = "pokemon_data"
SPRITES_DIR = "sprites"
MAX_ID = 905
DOWNLOAD_SPRITES = True  # passe à False si tu veux juste les JSON

# === Création des dossiers ===
os.makedirs(OUTPUT_DIR, exist_ok=True)
if DOWNLOAD_SPRITES:
    os.makedirs(SPRITES_DIR, exist_ok=True)

# === Boucle principale ===
for pokemon_id in range(1, MAX_ID + 1):
    try:
        print(f"Fetching Pokémon {pokemon_id}...")

        # Données principales
        url = f"https://pokeapi.co/api/v2/pokemon/{pokemon_id}"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()

        # Informations demandées
        pokemon_info = {
            "id": data["id"],
            "name": data["name"],
            "height": data["height"],
            "weight": data["weight"],
            "abilities": data["abilities"],
            "moves": data["moves"],
            "sprites": data["sprites"],
            "stats": data["stats"],
            "types": data["types"],
        }

        # Lieux d'apparition
        encounter_url = data["location_area_encounters"]
        encounter_data = requests.get(encounter_url).json()
        pokemon_info["location_area_encounters"] = encounter_data

        # Sauvegarde JSON local
        with open(f"{OUTPUT_DIR}/{pokemon_id:03d}_{data['name']}.json", "w", encoding="utf-8") as f:
            json.dump(pokemon_info, f, ensure_ascii=False, indent=2)

        # Téléchargement sprite principal (optionnel)
        if DOWNLOAD_SPRITES and data["sprites"]["front_default"]:
            sprite_url = data["sprites"]["front_default"]
            img_data = requests.get(sprite_url).content
            with open(f"{SPRITES_DIR}/{pokemon_id:03d}_{data['name']}.png", "wb") as img_file:
                img_file.write(img_data)

        # Petite pause pour éviter de saturer l’API
        time.sleep(0.3)

    except Exception as e:
        print(f"❌ Erreur pour Pokémon {pokemon_id}: {e}")
        continue

print("✅ Extraction terminée !")
