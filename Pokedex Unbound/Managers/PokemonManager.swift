//
//  PokemonManager.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 05/11/2025.
//

import Foundation
import UIKit



class PokemonManager {
    
    func getPokemon() -> [Pokemon] {
        // Get all the JSON files of the bundle
        guard let resourcePath = Bundle.main.resourcePath else {
            print("Could not find resource path")
            return []
        }
        
        let fileManager = FileManager.default
        var pokemonList: [Pokemon] = []
        
        // Read all the files of the bundle
        if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
            for file in files where file.hasSuffix(".json") {
                // Extract the name and the ID of the file (ex: "025_pikachu.json")
                let fileName = file.replacingOccurrences(of: ".json", with: "")
                let components = fileName.split(separator: "_")
                
                if components.count == 2,
                   let id = components.first,
                   let name = components.last {
                    let pokemon = Pokemon(
                        name: String(name),
                        url: String(id)
                    )
                    pokemonList.append(pokemon)
                }
            }
        }
        
        // Sort by ID
        return pokemonList.sorted { extractID(from: $0.url) < extractID(from: $1.url) }
    }
    
    func getDetailedPokemon(name: String) -> DetailPokemon? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        let fileManager = FileManager.default
        
        if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
            // Chercher un fichier qui se termine par "_name.json"
            if let matchingFile = files.first(where: { $0.lowercased().hasSuffix("_\(name.lowercased()).json") }) {
                let fileName = matchingFile.replacingOccurrences(of: ".json", with: "")
                return Bundle.main.decodeOptional(file: fileName)
            }
        }
        
        return nil
    }
    
    func getSprite(for pokemon: Pokemon) -> UIImage? {
        let index = extractID(from: pokemon.url)
        // Formater avec 3 chiffres (001, 025, 152, etc.)
        let fileName = String(format: "%03d_%@", index, pokemon.name.lowercased())
        return Bundle.main.image(file: fileName)
    }
    
    private func extractID(from fileName: String) -> Int {
        let components = fileName.split(separator: "_")
        if let first = components.first, let id = Int(first) { return id }
        return 9999
    }
}
