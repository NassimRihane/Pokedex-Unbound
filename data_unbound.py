import requests
from bs4 import BeautifulSoup
import json
import os
import re
from pathlib import Path

class UnboundLocationScraper:
    def __init__(self, json_directory="pokemon_data"):
        self.base_url = "https://unboundwiki.com/pokemon/"
        self.json_dir = Path(json_directory)
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
        
        # Mapping capture methods
        self.method_mapping = {
            'egg lady': 'gift',
            'randomly obtained': 'gift',
            'gift': 'gift',
            'trade': 'trade',
            'evolution': 'evolution',
            'starter': 'starter',
            'mission': 'mission',
            'swarm': 'swarm',
            'event': 'event',
            'fishing': 'fishing',
            'surfing': 'surf',
            'rock smash': 'rock-smash',
            'headbutt': 'headbutt',
            'grass': 'walk',
            'cave': 'walk',
            'walk': 'walk'
        }
    
    def normalize_location_name(self, location):
        """Normalize name to JSON format"""
        location = location.lower()
        location = re.sub(r'[^\w\s-]', '', location)
        location = re.sub(r'\s+', '-', location.strip())
        return location
    
    def parse_method(self, location_text):
        text_lower = location_text.lower()
        
        for keyword, method in self.method_mapping.items():
            if keyword in text_lower:
                return method
        
        # default method
        return 'walk'
    
    def scrape_pokemon_list(self):
        """Scrape the list of Pokemon from a webpage"""
        try:
            response = self.session.get(self.base_url)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            
            pokemon_data = []
            rows = soup.find_all('tr')
            
            for row in rows:
                cols = row.find_all('td')
                if len(cols) >= 5:
                    # Dex ID
                    number = cols[0].get_text(strip=True)
                    
                    # Name and link
                    link_tag = cols[2].find('a')
                    if link_tag:
                        name = link_tag.get_text(strip=True)
                        url = link_tag['href']
                        
                        # Location
                        location_cell = cols[4]
                        location_main = location_cell.find('strong')
                        location_detail = location_cell.get_text(strip=True)
                        
                        if location_main:
                            location_name = location_main.get_text(strip=True)
                        
                            location_detail = location_detail.replace(location_name, '', 1).strip()
                        else:
                            location_name = "Unknown"
                        
                        pokemon_data.append({
                            'number': number,
                            'name': name,
                            'url': url,
                            'location': location_name,
                            'location_detail': location_detail
                        })
            
            print(f"✅ {len(pokemon_data)} Pokémon found")
            return pokemon_data
        
        except Exception as e:
            print(f"❌ Scraping error: {e}")
            return []
    
    def get_pokemon_json_path(self, pokemon_name):
        """Find corresponding JSON"""

        name_lower = pokemon_name.lower()
        base_name = name_lower.split('-')[0] if '-' in name_lower else name_lower
        
        # Format [id]_[name].json
        for json_file in self.json_dir.glob("*_*.json"):
            
            file_name = json_file.stem
            if '_' in file_name:
                file_pokemon_name = file_name.split('_', 1)[1].lower() 
                
                # Check for regional forms
                if file_pokemon_name == name_lower or file_pokemon_name == base_name:
                    return json_file
        
        return None
    
    def parse_locations(self, location_text):
        """Parse multiple locations"""
 
        locations = [loc.strip() for loc in location_text.split(',')]
        return locations
    
    def add_location_to_json(self, pokemon_name, location_name, location_detail):
        """Add location data to JSON"""
        json_path = self.get_pokemon_json_path(pokemon_name)
        
        if not json_path:
            print(f"  ⚠️ JSON not found for {pokemon_name}")
            return False
        
        try:
            method = self.parse_method(location_detail)
            
            # Ignore evolves
            if method == 'evolution':
                print(f"  🚫 {pokemon_name}: Evolution ignored")
                return True
            
            with open(json_path, 'r', encoding='utf-8') as f:
                pokemon_data = json.load(f)
            
            if 'location_encounters_by_generation' not in pokemon_data:
                pokemon_data['location_encounters_by_generation'] = {}
            
            if 'Fan Games' not in pokemon_data['location_encounters_by_generation']:
                pokemon_data['location_encounters_by_generation']['Fan Games'] = {}
            
            fan_games = pokemon_data['location_encounters_by_generation']['Fan Games']
            
            locations = self.parse_locations(location_name)
            
            updated = False
            for single_location in locations:
                normalized_location = self.normalize_location_name(single_location)
                
                if normalized_location not in fan_games:
                    fan_games[normalized_location] = []
                
                # Check if an "Unbound entry already exists"
                unbound_entry = None
                for entry in fan_games[normalized_location]:
                    if 'unbound' in entry.get('versions', []):
                        unbound_entry = entry
                        break
            
                if unbound_entry:
                    # Check if method already exists
                    method_exists = any(
                        enc.get('method') == method 
                        for enc in unbound_entry.get('encounters', [])
                    )
                    
                    if not method_exists:
                        unbound_entry['encounters'].append({'method': method})
                        print(f"  + {pokemon_name}: Method '{method}' added to {normalized_location}")
                        updated = True
                else:
                    # Create new entry
                    new_entry = {
                        'versions': ['unbound'],
                        'encounters': [{'method': method}]
                    }
                    fan_games[normalized_location].append(new_entry)
                    print(f"  + {pokemon_name}: New location {normalized_location} with method '{method}'")
                    updated = True
            
            if not updated:
                print(f"  = {pokemon_name}: No changed needed")
            
            # Save JSON
            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(pokemon_data, f, indent=4, ensure_ascii=False)
            
            return True
        
        except Exception as e:
            print(f"  ❌ Error for {pokemon_name}: {e}")
            return False
    
    def process_all_pokemon(self):
        pokemon_list = self.scrape_pokemon_list()
        
        if not pokemon_list:
            print("Aucun Pokémon à traiter")
            return
        
        success_count = 0
        skip_count = 0
        error_count = 0
        
        print(f"\n🔄 Process of {len(pokemon_list)} Pokémon...\n")
        
        for pkmn in pokemon_list:
            if pkmn['location'] == 'N/A' or pkmn['location'] == 'Unknown':
                skip_count += 1
                continue
            
            result = self.add_location_to_json(
                pkmn['name'],
                pkmn['location'],
                pkmn['location_detail']
            )
            
            if result:
                success_count += 1
            else:
                error_count += 1
        
        print(f"\n📊 Summary:")
        print(f"  ✅ Success: {success_count}")
        print(f"  🚫 Ignored: {skip_count}")
        print(f"  ❌ Errodrs: {error_count}")


def main():
    # Path to pokemon data folder
    json_directory = "pokemon_data" 
    
    scraper = UnboundLocationScraper(json_directory)
    scraper.process_all_pokemon()


if __name__ == "__main__":
    main()