//
//  PokemonDetailView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 06/11/2025.
//

import SwiftUI


struct PokemonDetailView: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon
    
    var body: some View {
        VStack(spacing: 20) {
            
            PokemonView(pokemon: pokemon)
            
            // Details from local files
            if let details = vm.pokemonDetails {
                VStack(spacing: 10) {
                    Text("**ID**: \(details.id)")
                    Text("**Height**: \(vm.formatHW(value: details.height)) m")
                    Text("**Weight**: \(vm.formatHW(value: details.weight)) kg")
                    
                    // Display types
                    Text("**Types**: \(details.types.map { $0.type.name.capitalized }.joined(separator: ", "))")
                    
                    // Main stats
                    VStack {
                        Text("**Base Stats:**")
                            .font(.headline)
                        ForEach(details.stats, id: \.stat.name) { stat in
                            Text("\(stat.stat.name.capitalized): \(stat.base_stat)")
                        }
                     }
                }
                .padding()
            } else {
                ProgressView("Loading details...")
                    .onAppear {
                        vm.loadLocalDetails(for: pokemon)
                    }
            }
        }
        .navigationTitle(pokemon.name.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PokemonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PokemonDetailView(pokemon: Pokemon.samplePokemon)
            .environmentObject(ViewModel())
    }
}
