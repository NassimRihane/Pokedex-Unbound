import requests
import json
import os
import time
from collections import defaultdict

# === Configuration ===
OUTPUT_DIR = "pokemon_data"
START_ID = 1
MAX_ID = 905

# Mapping of versions to generations
VERSION_TO_GENERATION = {
    # Gen 1
    "red": "Generation I",
    "blue": "Generation I",
    "yellow": "Generation I",
    # Gen 2
    "gold": "Generation II",
    "silver": "Generation II",
    "crystal": "Generation II",
    # Gen 3
    "ruby": "Generation III",
    "sapphire": "Generation III",
    "emerald": "Generation III",
    "firered": "Generation III",
    "leafgreen": "Generation III",
    # Gen 4
    "diamond": "Generation IV",
    "pearl": "Generation IV",
    "platinum": "Generation IV",
    "heartgold": "Generation IV",
    "soulsilver": "Generation IV",
    # Gen 5
    "black": "Generation V",
    "white": "Generation V",
    "black-2": "Generation V",
    "white-2": "Generation V",
    # Gen 6
    "x": "Generation VI",
    "y": "Generation VI",
    "omega-ruby": "Generation VI",
    "alpha-sapphire": "Generation VI",
    # Gen 7
    "sun": "Generation VII",
    "moon": "Generation VII",
    "ultra-sun": "Generation VII",
    "ultra-moon": "Generation VII",
    # Gen 8
    "sword": "Generation VIII",
    "shield": "Generation VIII",
}

def get_ability_description(ability_url):
    """
    Get the ability description in english from the url
    """
    try:
        response = requests.get(ability_url)
        response.raise_for_status()
        ability_data = response.json()
        
        # Search the flavor_text en anglais (latest)
        flavor_texts = ability_data.get("flavor_text_entries", [])
        english_texts = [
            entry["flavor_text"] 
            for entry in flavor_texts 
            if entry["language"]["name"] == "en"
        ]
        
        if english_texts:
            return english_texts[-1].replace("\n", " ").replace("\f", " ")
        
        return None
        
    except Exception as e:
        print(f"    ! Error for talent: {e}")
        return None

def process_abilities(abilities_data):
    """
    Add the description to the ability
    """
    enriched_abilities = []
    
    for ability_entry in abilities_data:
        ability_name = ability_entry["ability"]["name"]
        ability_url = ability_entry["ability"]["url"]
        
        print(f"    Fetching description for {ability_name}...")
        description = get_ability_description(ability_url)
        
        enriched_abilities.append({
            "ability": {
                "name": ability_name,
                "url": ability_url,
                "description": description
            },
            "is_hidden": ability_entry["is_hidden"],
            "slot": ability_entry["slot"]
        })
        
        # Pause not to overload the API
        #time.sleep(0.1)
    
    return enriched_abilities

def consolidate_encounters(encounters):
    """
    Merge the encounters with the same method
    """
    # Group by method
    method_groups = defaultdict(list)
    
    for encounter in encounters:
        method = encounter["method"]
        method_groups[method].append(encounter)
    
    # Merge
    consolidated = []
    for method, group in method_groups.items():
        min_level = min(e["min_level"] for e in group)
        max_level = max(e["max_level"] for e in group)
        total_chance = sum(e["chance"] for e in group)
        
        consolidated.append({
            "method": method,
            "min_level": min_level,
            "max_level": max_level,
            "chance": total_chance
        })
    
    return consolidated

def process_encounters(encounter_data):
    """
    Process the encounter data and group by generations.
    """
    if not encounter_data:
        return {"message": "No encounter data available"}
    
    # Group by generation, then location
    generation_data = defaultdict(lambda: defaultdict(list))
    
    for location_entry in encounter_data:
        location_name = location_entry["location_area"]["name"]
        
        # Group the versions by generation for this location
        version_encounters = defaultdict(list)
        
        for version_detail in location_entry["version_details"]:
            version_name = version_detail["version"]["name"]
            generation = VERSION_TO_GENERATION.get(version_name, "Unknown")
            
            encounters = []
            for encounter in version_detail["encounter_details"]:
                encounters.append({
                    "method": encounter["method"]["name"],
                    "min_level": encounter["min_level"],
                    "max_level": encounter["max_level"],
                    "chance": encounter["chance"]
                })
            
            version_encounters[generation].append({
                "version": version_name,
                "encounters": encounters
            })
        
        # For each generation, try to merge versions with identical encounters
        for generation, version_list in version_encounters.items():
            if len(version_list) > 1:
                consolidated_version_list = []
                for v in version_list:
                    consolidated_version_list.append({
                        "version": v["version"],
                        "encounters": consolidate_encounters(v["encounters"])
                    })
                
                # Check if all versions have the same consolidated encounters
                first_encounters = sorted(
                    [json.dumps(e, sort_keys=True) for e in consolidated_version_list[0]["encounters"]]
                )
                all_same = all(
                    sorted([json.dumps(e, sort_keys=True) for e in v["encounters"]]) == first_encounters
                    for v in consolidated_version_list
                )
                
                if all_same:
                    versions = [v["version"] for v in consolidated_version_list]
                    generation_data[generation][location_name].append({
                        "versions": versions,
                        "encounters": consolidated_version_list[0]["encounters"]
                    })
                else:
                    # Keep separated but with consolidated encounters
                    for version_info in consolidated_version_list:
                        generation_data[generation][location_name].append({
                            "versions": [version_info["version"]],
                            "encounters": version_info["encounters"]
                        })
            else:
                # Only one version - consolidate its encounters
                consolidated = consolidate_encounters(version_list[0]["encounters"])
                generation_data[generation][location_name].append({
                    "versions": [version_list[0]["version"]],
                    "encounters": consolidated
                })
    
    # Convert in final format
    result = {}
    for generation, locations in generation_data.items():
        result[generation] = dict(locations)
    
    return result if result else {"message": "No encounter data available"}

def update_pokemon_data(pokemon_id):
    """
    Update encounter data and ability descriptions for existing Pokemon
    Only updates fields that are missing or need updating
    """
    # Find the existing file
    pattern = f"{pokemon_id:03d}_"
    filename = None
    for fname in os.listdir(OUTPUT_DIR):
        if fname.startswith(pattern) and fname.endswith(".json"):
            filename = fname
            break
    
    if not filename:
        print(f"  ! File not found for ID {pokemon_id}")
        return False
    
    filepath = os.path.join(OUTPUT_DIR, filename)
    
    # Load the existing JSON
    with open(filepath, "r", encoding="utf-8") as f:
        pokemon_data = json.load(f)
    
    pokemon_name = pokemon_data["name"]
    print(f"  Updating data for {pokemon_name}...")
    
    data_modified = False
    
    try:
        # Update abilities with descriptions (only if not already present)
        if "abilities" in pokemon_data:
            # Check if descriptions are already present
            has_descriptions = all(
                "description" in ability.get("ability", {})
                for ability in pokemon_data["abilities"]
            )
            
            if not has_descriptions:
                print(f"    Processing abilities...")
                enriched_abilities = process_abilities(pokemon_data["abilities"])
                pokemon_data["abilities"] = enriched_abilities
                data_modified = True
            else:
                print(f"    Abilities already have descriptions, skipping...")
        
        # Update encounters - toujours retraiter pour consolider
        if "location_area_encounters" in pokemon_data:
            print(f"    Removing old encounter format...")
            del pokemon_data["location_area_encounters"]
            data_modified = True
        
        has_new_format = "location_encounters_by_generation" in pokemon_data
        
        if not has_new_format or data_modified:
            print(f"    Processing encounters...")
            pokemon_id_from_data = pokemon_data["id"]
            encounter_url = f"https://pokeapi.co/api/v2/pokemon/{pokemon_id_from_data}/encounters"
            
            response = requests.get(encounter_url)
            response.raise_for_status()
            encounter_data = response.json()
            
            # Process and group encounters (consolidated)
            processed_encounters = process_encounters(encounter_data)
            pokemon_data["location_encounters_by_generation"] = processed_encounters
            data_modified = True
        else:
            print(f"    Encounters already processed, skipping...")
        
        # Save only if modified
        if data_modified:
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(pokemon_data, f, ensure_ascii=False, indent=2)
            print(f"  ✓ Data updated for {pokemon_name}")
        else:
            print(f"  ✓ No updates needed for {pokemon_name}")
        
        return True
        
    except Exception as e:
        print(f"  x Error updating data: {e}")
        return False

# === Main loop ===
print(f"Updating Pokemon data from ID {START_ID} to {MAX_ID}")
print("-" * 50)

success_count = 0
error_count = 0

for pokemon_id in range(START_ID, MAX_ID + 1):
    try:
        print(f"Processing Pokémon {pokemon_id}...")
        
        if update_pokemon_data(pokemon_id):
            success_count += 1
        else:
            error_count += 1
        
        # Pause to avoid overloading the API
        #time.sleep(0.5)  # Augmenté pour les appels supplémentaires
        
    except Exception as e:
        print(f"x Error for Pokémon {pokemon_id}: {e}")
        error_count += 1
        continue

print("-" * 50)
print(f"✓ Update finished!")
print(f"   Success: {success_count}")
print(f"   Errors: {error_count}")