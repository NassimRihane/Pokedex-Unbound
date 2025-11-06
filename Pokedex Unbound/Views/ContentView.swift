//
//  ContentView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 27/10/2025.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var vm = ViewModel()
    
    private let adaptativeColumns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: adaptativeColumns, spacing: 10){
                    ForEach(vm.filteredPokemon){ pokemon in
                        NavigationLink(destination: PokemonDetailView(pokemon: pokemon)){
                            PokemonView(pokemon: pokemon)
                        }
                    }
                }
                .animation(.easeIn(duration: 0.3), value: vm.filteredPokemon.count)
                .navigationTitle("PokemonUI")
                //.navigationBarTitleDisplayMode(.inline)
            }
            .searchable(text: $vm.searchText)
        }
        .padding()
        .environmentObject(vm)
    }
}

#Preview {
    ContentView()
}
// test github
