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

def process_encounters(encounter_data):
    """
    Process the encounter data and group by generations.
    If methods are identical between versions in same generation,
    it fuses it the same entry.
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
            
            # Extract the encounter details
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
        
        # For each generation, try to merge them
        for generation, version_list in version_encounters.items():
            if len(version_list) > 1:
                # Check if all versions have the same type of encounter
                first_encounters = sorted(
                    [json.dumps(e, sort_keys=True) for e in version_list[0]["encounters"]]
                )
                all_same = all(
                    sorted([json.dumps(e, sort_keys=True) for e in v["encounters"]]) == first_encounters
                    for v in version_list
                )
                
                if all_same:
                    # Merge in the same entry for all versions
                    versions = [v["version"] for v in version_list]
                    generation_data[generation][location_name].append({
                        "versions": versions,
                        "encounters": version_list[0]["encounters"]
                    })
                else:
                    # Keep separated
                    for version_info in version_list:
                        generation_data[generation][location_name].append({
                            "versions": [version_info["version"]],
                            "encounters": version_info["encounters"]
                        })
            else:
                # Only one version
                generation_data[generation][location_name].append({
                    "versions": [version_list[0]["version"]],
                    "encounters": version_list[0]["encounters"]
                })
    
    # Convert in final format
    result = {}
    for generation, locations in generation_data.items():
        result[generation] = dict(locations)
    
    return result if result else {"message": "No encounter data available"}

def update_pokemon_encounters(pokemon_id):
    """
    Update only the data for existing Pokemon
    """
    # Find the existing file
    pattern = f"{pokemon_id:03d}_"
    filename = None
    for fname in os.listdir(OUTPUT_DIR):
        if fname.startswith(pattern) and fname.endswith(".json"):
            filename = fname
            break
    
    if not filename:
        print(f"  x File not found for ID {pokemon_id}")
        return False
    
    filepath = os.path.join(OUTPUT_DIR, filename)
    
    # Charge the existing JSON
    with open(filepath, "r", encoding="utf-8") as f:
        pokemon_data = json.load(f)
    
    pokemon_name = pokemon_data["name"]
    print(f"  Updating encounters for {pokemon_name}...")
    
    # Get new encounter data
    pokemon_id_from_data = pokemon_data["id"]
    encounter_url = f"https://pokeapi.co/api/v2/pokemon/{pokemon_id_from_data}/encounters"
    
    try:
        response = requests.get(encounter_url)
        response.raise_for_status()
        encounter_data = response.json()
        
        # Process and group encounters
        processed_encounters = process_encounters(encounter_data)
        
        # Update
        pokemon_data["location_encounters_by_generation"] = processed_encounters
        
        # Save
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(pokemon_data, f, ensure_ascii=False, indent=2)
        
        print(f"  ✓ Encounters updated for {pokemon_name}")
        return True
        
    except Exception as e:
        print(f"  x Error updating encounters: {e}")
        return False

# === Main loop ===
print(f"Updating encounter data from ID {START_ID} to {MAX_ID}")
print("-" * 50)

success_count = 0
error_count = 0

for pokemon_id in range(START_ID, MAX_ID + 1):
    try:
        print(f"Processing Pokémon {pokemon_id}...")
        
        if update_pokemon_encounters(pokemon_id):
            success_count += 1
        else:
            error_count += 1
        
        # Pause to avoid overloading the API
        time.sleep(0.3)
        
    except Exception as e:
        print(f"x Error for Pokémon {pokemon_id}: {e}")
        error_count += 1
        continue

print("-" * 50)
print(f"v Update finished")
print(f"   Success: {success_count}")
print(f"   Errors: {error_count}")