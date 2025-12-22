//
//  ViewModel.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 05/11/2025.
//

import Foundation
import SwiftUI
import Combine




@MainActor
final class ViewModel: ObservableObject {
    private let pokemonManager = PokemonManager()
    
    @Published var pokemonList = [Pokemon]()
    @Published var pokemonDetails: DetailPokemon?
    @Published var searchText = ""
    
    // Cache to quickly reach translated names and types
    private var translatedNamesCache: [String: (nameJp: String?, nameFr: String?)] = [:]
    
    private var typesCache: [String: Set<String>] = [:]
    
    var filteredPokemon: [Pokemon] {
        if searchText.isEmpty{
            return pokemonList
        }
        
        let searchLower = searchText.lowercased()
        
        return pokemonList.filter { pokemon in
            if pokemon.name.lowercased().contains(searchLower){
                return true
            }
            
            let translatedNames = getTranslatedNames(for: pokemon)
            
            if let nameJp = translatedNames.nameJp,
               nameJp.lowercased().contains(searchLower){
                return true
            }
            
            if let nameFr = translatedNames.nameFr,
               nameFr.lowercased().contains(searchLower){
                return true
            }
            
            return false
        }
    }
    
    init() {
        self.pokemonList = pokemonManager.getPokemon()
        preloadTranslatedNames()
    }
    
    func getDetails(pokemon: Pokemon) {
        if let detail = pokemonManager.getDetailedPokemon(name: pokemon.url) {
            self.pokemonDetails = detail
        }
    }
    
    func getPokemonIndex(pokemon: Pokemon) -> Int {
        if let index = self.pokemonList.firstIndex(of: pokemon){
            return index + 1
        }
        return 0
    }
    
    func formatHW(value: Int) -> String {
        let dValue = Double(value)
        let string = String(format: "%.2f", dValue / 10)
    
        return string
    }
    
    private func getTranslatedNames(for pokemon: Pokemon) -> (nameJp: String?, nameFr: String?){
        let key = pokemon.name
        
        if let cached = translatedNamesCache[key]{
            return cached
        }
        
        let index = getPokemonIndex(pokemon: pokemon)
        let formattedIndex = String(format: "%03d", index)
        let fileName = "\(formattedIndex)_\(pokemon.name.lowercased())"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(DetailPokemon.self, from: data) else{
            translatedNamesCache[key] = (nil,nil)
            return (nil,nil)
        }
        
        let names = (nameJp: decoded.nameJp, nameFr: decoded.nameFr)
        translatedNamesCache[key] = names
        return names
    }
    
    private func preloadTranslatedNames() {
        Task { [weak self] in
            guard let self else { return }
            for pokemon in self.pokemonList {
                _ = self.getTranslatedNames(for: pokemon)
            }
            print("Preloaded \(self.translatedNamesCache.count) translated names")
        }
    }
    
    func clearPokemonDetails() {
        DispatchQueue.main.async{
            self.pokemonDetails = nil
        }
    }
    
    func getPokemonTypes(for pokemon: Pokemon) -> Set<String>{
        let key = pokemon.name
        
        if let cached = typesCache[key]{
            return cached
        }
        
        let pokemonId = extractIDFromURL(pokemon.url)
        let formattedIndex = String(format: "%03d", pokemonId)
        let fileName = "\(formattedIndex)_\(pokemon.name.lowercased())"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(DetailPokemon.self, from: data) else {
            return []
        }
        
        return Set(decoded.types.map {$0.type.name})
    }
    
    func extractIDFromURL(_ url: String) -> Int{
        let components = url.split(separator: "/")
        if let idString = components.last(where: {Int($0) != nil}),
           let id = Int(idString){
            return id
        }
        return 0
    }
    
}



extension ViewModel {
    func loadLocalDetails(for pokemon: Pokemon) {
        // Format the index with 3 digits (001, 025, 152, etc.)
        let index = getPokemonIndex(pokemon: pokemon)
        let formattedIndex = String(format: "%03d", index)
        let fileName = "\(formattedIndex)_\(pokemon.name.lowercased())"
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(DetailPokemon.self, from: data)
                DispatchQueue.main.async {
                    self.pokemonDetails = decoded
                }
            } catch {
                print("Decoding error for \(fileName): \(error)")
            }
        } else {
            print("File not found for \(fileName).json in Data/pokemon_data")
        }
    }
}

