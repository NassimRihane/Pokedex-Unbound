//
//  PokemonZonesView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 09/12/2025.
//

import SwiftUI

// New Data structures
struct LocationEncountersByGeneration: Codable {
    let generationData: [String: GenerationEncounters]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        generationData = try container.decode([String: GenerationEncounters].self)
    }
}

struct GenerationEncounters: Codable {
    let locations: [String: [VersionEncounter]]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        locations = try container.decode([String: [VersionEncounter]].self)
    }
}

struct VersionEncounter: Codable {
    let versions: [String]
    let encounters: [EncounterDetail]
}

struct EncounterDetail: Codable {
    let method: String
    let min_level: Int
    let max_level: Int
    let chance: Int
}



struct PokemonZonesView: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                if let details = vm.pokemonDetails {
                    if let encountersData = details.location_encounters_by_generation {
                        
                       
                        let sortedGenerations = encountersData.generationData.keys.sorted { gen1, gen2 in
                            let num1 = extractGenerationNumber(from: gen1)
                            let num2 = extractGenerationNumber(from: gen2)
                            return num1 < num2
                        }
                        
                       // Uses the accordion architecture implemented below
                        ForEach(sortedGenerations, id: \.self) { generation in
                            if let genData = encountersData.generationData[generation] {
                                GenerationAccordion(
                                    generationName: generation,
                                    locations: genData.locations
                                )
                            }
                        }
                        
                    } else {
                        // No zone available
                        VStack(spacing: 10) {
                            Image(systemName: "location.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No encounter locations available")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                    }
                } else {
                    ProgressView("Loading zones...")
                        .padding(.top, 50)
                }
            }
            .padding()
        }
    }
    
    private func extractGenerationNumber(from generation: String) -> Int {
        let romanToInt = [
            "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5,
            "VI": 6, "VII": 7, "VIII": 8, "IX": 9
        ]
        
        let components = generation.split(separator: " ")
        if components.count == 2, let roman = components.last {
            return romanToInt[String(roman)] ?? 999
        }
        return 999
    }
}


struct GenerationAccordion: View {
    let generationName: String
    let locations: [String: [VersionEncounter]]
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "gamecontroller.fill") // Replace by custom icon
                        .foregroundColor(.red)
                        .font(.title3)
                    
                    Text(generationName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(locations.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(12)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(locations.keys.sorted()), id: \.self) { locationName in
                        if let versionEncounters = locations[locationName] {
                            LocationCard(
                                locationName: locationName,
                                versionEncounters: versionEncounters
                            )
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}


struct LocationCard: View {
    let locationName: String
    let versionEncounters: [VersionEncounter]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                
                Text(locationName.capitalized.replacingOccurrences(of: "-", with: " "))
                    .font(.headline)
            }
            .padding(.bottom, 4)
            

            ForEach(Array(versionEncounters.enumerated()), id: \.offset) { index, versionEncounter in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        ForEach(versionEncounter.versions, id: \.self) { version in
                            Text(version.capitalized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(versionColor(for: version))
                                .cornerRadius(8)
                        }
                    }
                    
                    ForEach(Array(versionEncounter.encounters.enumerated()), id: \.offset) { _, encounter in
                        HStack(spacing: 12) {

                            Text(methodIcon(for: encounter.method))
                                .font(.caption)
                            
                            Text(encounter.method.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            

                            if encounter.min_level == encounter.max_level {
                                Text("Lv.\(encounter.min_level)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            } else {
                                Text("Lv.\(encounter.min_level)-\(encounter.max_level)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            

                            Text("\(encounter.chance)%")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    

    private func methodIcon(for method: String) -> String {
        switch method.lowercased() {
        case "walk": return "👣"
        case "surf": return "🌊"
        case "old-rod", "good-rod", "super-rod": return "🎣"
        case "gift": return "🎁"
        case "rock-smash": return "🪨"
        case "island-scan": return "🔎"
        default: return "❓"
        }
    }
    
 
    private func versionColor(for version: String) -> Color {
        switch version.lowercased() {
        case "red", "ruby", "omega-ruby": return Color.red
        case "blue", "sapphire", "alpha-sapphire": return Color.blue
        case "yellow": return Color.yellow
        case "gold": return Color.orange
        case "silver": return Color.gray
        case "crystal": return Color.cyan
        case "diamond": return Color.blue.opacity(0.8)
        case "pearl": return Color.pink
        case "platinum": return Color.gray.opacity(0.7)
        case "heartgold": return Color.yellow
        case "soulsilver": return Color.gray.opacity(0.7)
        case "black": return Color.black
        case "white": return Color.white.opacity(0.8)
        case "x": return Color.blue
        case "y": return Color.red
        case "sun": return Color.orange.opacity(0.7)
        case "moon": return Color.indigo.opacity(0.7)
        case "ultra-sun": return Color.orange
        case "ultra-moon": return Color.indigo
        case "sword": return Color.cyan
        case "shield": return Color.red.opacity(0.7)
        default: return Color.gray
        }
    }
}


struct PokemonZonesView_Previews: PreviewProvider {
    static var previews: some View {
        PokemonZonesView(pokemon: Pokemon.samplePokemon)
            .environmentObject(ViewModel())
    }
}
