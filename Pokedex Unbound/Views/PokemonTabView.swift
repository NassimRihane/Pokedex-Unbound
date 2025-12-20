//
//  PokemonTabView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 08/12/2025.
//

import SwiftUI

struct PokemonTabView: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon
    
    
    var body: some View {
        TabView{
            Tab("Details", systemImage: "info.circle"){
                PokemonDetailView(pokemon: pokemon)
            }
            
            Tab("Moves", systemImage: "bolt.fill"){
                PokemonMovesView(pokemon: pokemon)
            }
            
            Tab("Zones", systemImage: "map"){
                PokemonZonesView(pokemon: pokemon)
            }
        }
        .navigationTitle(pokemon.name.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .id(pokemon.name)
        .task(id: pokemon.id){
            vm.clearPokemonDetails()
            vm.loadLocalDetails(for: pokemon)
        }
        .onAppear {
            print("TabView vm object id: \(Unmanaged.passUnretained(vm).toOpaque())")
        }
    }
}

// Preview
struct PokemonTabbedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PokemonTabView(pokemon: Pokemon.samplePokemon)
                .environmentObject(ViewModel())
        }
    }
}
