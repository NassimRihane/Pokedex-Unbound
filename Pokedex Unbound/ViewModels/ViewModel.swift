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

    // Caches to quickly reach translated names, types and stats.
    // They are filled at launch from pokedex-index.json; on a cache miss (no index),
    // the full JSON file of the Pokemon is decoded once and the result is stored.
    private var translatedNamesCache: [String: (nameJp: String?, nameFr: String?)] = [:]

    private var typesCache: [String: Set<String>] = [:]

    // Quick access to a Pokemon from its file name (used by the evolution chain)
    private var pokemonByFile: [String: Pokemon] = [:]

    var filteredPokemon: [Pokemon] {
        if searchText.isEmpty{
            return pokemonList
        }

        let searchLower = searchText.lowercased()

        return pokemonList.filter { pokemon in
            if pokemon.name.lowercased().contains(searchLower) || pokemon.displayName.lowercased().contains(searchLower){
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
        let index = pokemonManager.loadIndex()
        self.pokemonList = pokemonManager.getPokemon(index: index)
        self.pokemonByFile = Dictionary(pokemonList.map { ($0.fileName, $0) }, uniquingKeysWith: { first, _ in first })
        fillCaches(from: index)
        preloadTranslatedNames()
    }

    func getDetails(pokemon: Pokemon) {
        if let detail = pokemonManager.getDetailedPokemon(fileName: pokemon.fileName) {
            self.pokemonDetails = detail
        }
    }

    func pokemon(forFile fileName: String) -> Pokemon? {
        return pokemonByFile[fileName]
    }

    func formatHW(value: Int) -> String {
        let dValue = Double(value)
        let string = String(format: "%.2f", dValue / 10)

        return string
    }

    /// Decodes the full JSON file of a Pokemon (fallback when the index is missing)
    private func decodeFullFile(of pokemon: Pokemon) -> DetailPokemon? {
        guard let url = Bundle.main.url(forResource: pokemon.fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(DetailPokemon.self, from: data)
    }

    private func fillCaches(from index: [String: PokemonIndexEntry]) {
        for pokemon in pokemonList {
            guard let entry = index[pokemon.fileName] else { continue }
            translatedNamesCache[pokemon.name] = (nameJp: entry.nameJp, nameFr: entry.nameFr)
            typesCache[pokemon.name] = Set(entry.types)
            statsCache[pokemon.name] = PokemonStats(
                hp: entry.stats.hp,
                attack: entry.stats.attack,
                defense: entry.stats.defense,
                specialAttack: entry.stats.specialAttack,
                specialDefense: entry.stats.specialDefense,
                speed: entry.stats.speed
            )
        }
        print("Index loaded for \(translatedNamesCache.count)/\(pokemonList.count) Pokemon")
    }

    func getTranslatedNames(for pokemon: Pokemon) -> (nameJp: String?, nameFr: String?){
        let key = pokemon.name

        if let cached = translatedNamesCache[key]{
            return cached
        }

        guard let decoded = decodeFullFile(of: pokemon) else{
            translatedNamesCache[key] = (nil,nil)
            return (nil,nil)
        }

        let names = (nameJp: decoded.nameJp, nameFr: decoded.nameFr)
        translatedNamesCache[key] = names
        return names
    }

    // Only useful without index: reads the names of the Pokemon missing from the cache
    private func preloadTranslatedNames() {
        let missing = pokemonList.filter { translatedNamesCache[$0.name] == nil }
        guard !missing.isEmpty else { return }
        Task { [weak self] in
            guard let self else { return }
            for pokemon in missing {
                _ = self.getTranslatedNames(for: pokemon)
            }
            print("Preloaded \(missing.count) translated names")
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

        guard let decoded = decodeFullFile(of: pokemon) else {
            typesCache[key] = []
            return []
        }

        let types = Set(decoded.types.map {$0.type.name})
        typesCache[key] = types
        return types
    }


    // Stats for the slider filter
    struct PokemonStats{
        let hp: Int
        let attack: Int
        let defense: Int
        let specialAttack: Int
        let specialDefense: Int
        let speed: Int
    }

    private var statsCache: [String: PokemonStats] = [:]

    func getPokemonStats(for pokemon: Pokemon) -> PokemonStats{
        let key = pokemon.name

        if let cached = statsCache[key]{
            return cached
        }

        guard let decoded = decodeFullFile(of: pokemon) else{
            let emptyStats = PokemonStats(hp: 0, attack: 0, defense: 0, specialAttack: 0, specialDefense: 0, speed: 0)
            statsCache[key] = emptyStats
            return emptyStats
        }

        var hp = 0, attack = 0, defense = 0, specialAttack = 0, specialDefense = 0, speed = 0

        for stat in decoded.stats{
            switch stat.stat.name.lowercased(){
            case "hp": hp = stat.base_stat
            case "attack": attack = stat.base_stat
            case "defense": defense = stat.base_stat
            case "special-attack": specialAttack = stat.base_stat
            case "special-defense": specialDefense = stat.base_stat
            case "speed": speed = stat.base_stat
            default: break
            }
        }

        let stats = PokemonStats(
            hp: hp,
            attack: attack,
            defense: defense,
            specialAttack: specialAttack,
            specialDefense: specialDefense,
            speed: speed
        )

        statsCache[key] = stats
        return stats
    }

}



extension ViewModel {
    func loadLocalDetails(for pokemon: Pokemon) {
        let fileName = pokemon.fileName

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
