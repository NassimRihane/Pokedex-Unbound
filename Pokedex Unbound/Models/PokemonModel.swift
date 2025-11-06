//
//  PokemonModel.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 05/11/2025.
//


import Foundation

struct Pokemon: Codable, Identifiable, Equatable{
    let id = UUID()
    let name: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case name, url
    }
    
    static var samplePokemon = Pokemon(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/")
}

struct PokemonPage: Codable{
    let count: Int
    let next: String
    let results: [Pokemon]
}


struct DetailPokemon: Codable{
    let id: Int
    let height: Int
    let weight: Int
}
