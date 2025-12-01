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


struct DetailPokemon: Codable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let abilities: [Ability]
    let moves: [Move]
    let sprites: Sprites
    let stats: [Stat]
    let types: [TypeEntry]
    let location_area_encounters: [LocationAreaEncounter]?

    struct Ability: Codable {
        let ability: NamedAPIResource
    }
    struct Move: Codable {
        let move: NamedAPIResource
    }
    struct Sprites: Codable {
        let front_default: String?
    }
    struct Stat: Codable {
        let base_stat: Int
        let stat: NamedAPIResource
    }
    struct TypeEntry: Codable {
        let slot: Int
        let type: NamedAPIResource
    }
    struct NamedAPIResource: Codable {
        let name: String
        let url: String
    }
    struct LocationAreaEncounter: Codable {
        let location_area: NamedAPIResource
    }
}
