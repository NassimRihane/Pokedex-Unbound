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
    
    var filteredPokemon: [Pokemon] {
        searchText.isEmpty
            ? pokemonList
            : pokemonList.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    init() {
        self.pokemonList = pokemonManager.getPokemon()
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
