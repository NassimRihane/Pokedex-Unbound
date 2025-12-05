import requests
import json
import os
import time

# === Configuration ===
OUTPUT_DIR = "pokemon_data"
SPRITES_DIR = "sprites"
START_ID = 1  # Change cette valeur pour reprendre à un ID spécifique
MAX_ID = 905
DOWNLOAD_SPRITES = False  # passe à False si tu veux juste les JSON
SKIP_EXISTING = True  # Passe les Pokémon déjà téléchargés

# === Création des dossiers ===
os.makedirs(OUTPUT_DIR, exist_ok=True)
if DOWNLOAD_SPRITES:
    os.makedirs(SPRITES_DIR, exist_ok=True)

# === Fonction pour vérifier si un Pokémon existe déjà ===
def pokemon_already_exists(pokemon_id, pokemon_name=None):
    """Vérifie si le fichier JSON du Pokémon existe déjà"""
    # Chercher par ID avec pattern XXX_*.json
    pattern = f"{pokemon_id:03d}_"
    for filename in os.listdir(OUTPUT_DIR):
        if filename.startswith(pattern) and filename.endswith(".json"):
            return True
    return False

# === Fonction pour récupérer les noms traduits ===
def get_pokemon_names(species_url):
    """Récupère les noms en japonais (roomaji) et français depuis species"""
    try:
        response = requests.get(species_url)
        response.raise_for_status()
        species_data = response.json()
        
        names = {"name-jp": None, "name-fr": None}
        
        for name_entry in species_data.get("names", []):
            lang = name_entry["language"]["name"]
            if lang == "roomaji":
                names["name-jp"] = name_entry["name"]
            elif lang == "fr":
                names["name-fr"] = name_entry["name"]
        
        return names
    except Exception as e:
        print(f"  ⚠️ Erreur lors de la récupération des noms: {e}")
        return {"name-jp": None, "name-fr": None}

# === Fonction pour récupérer les détails d'une attaque ===
def get_move_details(move_url):
    """Récupère les détails d'une attaque depuis son URL"""
    try:
        response = requests.get(move_url)
        response.raise_for_status()
        move_data = response.json()
        
        return {
            "name": move_data["name"],
            "type": move_data["type"]["name"] if move_data.get("type") else None,
            "power": move_data.get("power"),
            "pp": move_data.get("pp"),
            "accuracy": move_data.get("accuracy")
        }
    except Exception as e:
        print(f"  ⚠️ Erreur lors de la récupération de l'attaque {move_url}: {e}")
        return None

# === Fonction pour filtrer les attaques ===
def filter_moves(moves_data):
    """Filtre les attaques selon les critères :
    - Gen 8 (Sword-Shield) en priorité, sinon Gen 7 (Ultra Sun/Moon)
    - Seulement level-up et machine
    """
    filtered_moves = []
    
    for move_entry in moves_data:
        move_name = move_entry["move"]["name"]
        move_url = move_entry["move"]["url"]
        version_details = move_entry["version_group_details"]
        
        # Chercher dans Sword-Shield (Gen 8)
        gen8_moves = [
            detail for detail in version_details
            if detail["version_group"]["name"] == "sword-shield"
            and detail["move_learn_method"]["name"] in ["level-up", "machine"]
        ]
        
        # Si pas trouvé, chercher dans Ultra Sun/Moon (Gen 7)
        gen7_moves = [
            detail for detail in version_details
            if detail["version_group"]["name"] == "ultra-sun-ultra-moon"
            and detail["move_learn_method"]["name"] in ["level-up", "machine"]
        ]
        
        # Prendre Gen 8 en priorité, sinon Gen 7
        selected_moves = gen8_moves if gen8_moves else gen7_moves
        
        # Ajouter chaque version filtrée
        for detail in selected_moves:
            # Récupérer les détails de l'attaque
            move_details = get_move_details(move_url)
            
            if move_details:
                filtered_moves.append({
                    "move": move_details,
                    "level_learned_at": detail["level_learned_at"],
                    "move_learn_method": detail["move_learn_method"]["name"],
                    "version_group": detail["version_group"]["name"]
                })
                
            # Pause pour éviter de surcharger l'API
            time.sleep(0.1)
    
    return filtered_moves

# === Boucle principale ===
print(f"Starting extraction from ID {START_ID} to {MAX_ID}")
print(f"Skip existing: {SKIP_EXISTING}")
print("-" * 50)

for pokemon_id in range(START_ID, MAX_ID + 1):
    try:
        # Vérifier si le Pokémon existe déjà
        if SKIP_EXISTING and pokemon_already_exists(pokemon_id):
            print(f"⏭️  Pokémon {pokemon_id} already exists, skipping...")
            continue
        
        print(f"Fetching Pokémon {pokemon_id}...")
        
        # Données principales
        url = f"https://pokeapi.co/api/v2/pokemon/{pokemon_id}"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        # Récupérer les noms traduits depuis species
        print(f"  Fetching translated names for {data['name']}...")
        species_url = data["species"]["url"]
        translated_names = get_pokemon_names(species_url)
        
        # Filtrer les attaques
        print(f"  Filtering moves for {data['name']}...")
        filtered_moves = filter_moves(data["moves"])
        print(f"  ✓ {len(filtered_moves)} moves retained (from {len(data['moves'])} total)")
        
        # Informations demandées
        pokemon_info = {
            "id": data["id"],
            "name": data["name"],
            "name-jp": translated_names["name-jp"],
            "name-fr": translated_names["name-fr"],
            "height": data["height"],
            "weight": data["weight"],
            "abilities": data["abilities"],
            "moves": filtered_moves,  # Attaques filtrées
            "sprites": data["sprites"],
            "stats": data["stats"],
            "types": data["types"],
        }
        
        # Lieux d'apparition
        encounter_url = data["location_area_encounters"]
        encounter_data = requests.get(encounter_url).json()
        pokemon_info["location_area_encounters"] = encounter_data
        
        # Sauvegarde JSON local
        filename = f"{OUTPUT_DIR}/{pokemon_id:03d}_{data['name']}.json"
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(pokemon_info, f, ensure_ascii=False, indent=2)
        
        print(f"  ✓ Saved to {filename}")
        
        # Téléchargement sprite principal (optionnel)
        if DOWNLOAD_SPRITES and data["sprites"]["front_default"]:
            sprite_url = data["sprites"]["front_default"]
            img_data = requests.get(sprite_url).content
            sprite_filename = f"{SPRITES_DIR}/{pokemon_id:03d}_{data['name']}.png"
            with open(sprite_filename, "wb") as img_file:
                img_file.write(img_data)
            print(f"  ✓ Sprite saved")
        
        # Petite pause pour éviter de saturer l'API
        time.sleep(0.5)
        
    except Exception as e:
        print(f"❌ Erreur pour Pokémon {pokemon_id}: {e}")
        continue

print("✅ Extraction terminée !")