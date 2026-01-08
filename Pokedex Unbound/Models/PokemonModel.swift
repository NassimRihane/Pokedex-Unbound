//
//  PokemonModel.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 05/11/2025.
//


import Foundation

struct Pokemon: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case name, url
    }
    
    static var samplePokemon = Pokemon(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/")
}

struct PokemonPage: Codable {
    let count: Int
    let next: String
    let results: [Pokemon]
}

struct DetailPokemon: Codable {
    let id: Int
    let name: String
    let nameJp: String
    let nameFr: String
    let height: Int
    let weight: Int
    let abilities: [AbilityEntry]
    let moves: [MoveEntry]
    let sprites: Sprites
    let stats: [Stat]
    let types: [TypeEntry]
    let location_encounters_by_generation: LocationEncountersByGeneration?
    
    enum CodingKeys: String, CodingKey {
        case id, name, height, weight, abilities, moves, sprites, stats, types
        case nameJp = "name-jp"
        case nameFr = "name-fr"
        case location_encounters_by_generation
    }

    
    struct MoveEntry: Codable {
        let move: MoveDetails
        let level_learned_at: Int
        let move_learn_method: String
        let version_group: String
    }
    
    struct MoveDetails: Codable {
        let name: String
        let type: String?
        let power: Int?
        let pp: Int?
        let accuracy: Int?
    }
    
    struct AbilityEntry: Codable {
        let ability: AbilityDetails
        let is_hidden: Bool
        let slot: Int
    }
    
    struct AbilityDetails: Codable {
        let name: String
        let description: String
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

extension DetailPokemon.MoveEntry{
    var uniqueID : String{
        return "\(move.name)_\(move_learn_method)_\(level_learned_at)_\(version_group)"
    }
}
