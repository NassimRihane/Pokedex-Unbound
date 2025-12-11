//
//  PokemonMovesView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 08/12/2025.
//

import SwiftUI

struct PokemonMovesView: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon
    
    @State private var selectedLearnMethod: String = "All"
    
    var body: some View{
        ScrollView{
            VStack{
                if let details = vm.pokemonDetails{
                    Picker("Learn Method", selection: $selectedLearnMethod){
                        Text("Level Up").tag("level-up")
                        Text("TM/HM").tag("machine")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    let filteredMoves = selectedLearnMethod == "All"
                        ? details.moves
                        : details.moves.filter { $0.move_learn_method == selectedLearnMethod }
                    
                    let sortedMoves = filteredMoves.sorted { (move1: DetailPokemon.MoveEntry, move2: DetailPokemon.MoveEntry) -> Bool in
                        if move1.move_learn_method == "level-up" && move2.move_learn_method == "level-up" {
                            return move1.level_learned_at < move2.level_learned_at
                        }
                        if move1.move_learn_method == "machine" && move2.move_learn_method == "machine" {
                            return move1.move.name < move2.move.name
                        }
                        return move1.move_learn_method == "level-up"
                    }

                    
                    if filteredMoves.isEmpty{
                        Text("Moves not found")
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    } else{
                        LazyVStack(spacing: 5) {
                            ForEach(sortedMoves, id: \.uniqueID) { moveEntry in
                                MoveCard(moveEntry: moveEntry)
                            }
                        }
                        .padding()
                    }
                }
                else {
                    ProgressView("Loading moves")
                        .padding(.top, 50)
                }
            }
        }
        .onAppear {
            print("MovesView vm object id: \(Unmanaged.passUnretained(vm).toOpaque())")
            print("PokemonMovesView onAppear - pokemonDetails is \(vm.pokemonDetails == nil ? "nil" : "loaded")")
        }    }
}


struct MoveCard: View{
    let moveEntry: DetailPokemon.MoveEntry
    
    var body: some View{
        VStack(alignment: .leading){
            HStack{
                Text(moveEntry.move.name.capitalized.replacingOccurrences(of: "-", with: " "))
                    .font(.headline)
                Spacer()
                
                if let type = moveEntry.move.type{
                    TypeImageView(typeName: type)
                }
            }
            
            HStack{
                //Power PP and Accuracy
                if let power = moveEntry.move.power{
                    StatPill(label: "Power", value: "\(power)")
                }
                if let pp = moveEntry.move.pp{
                    StatPill(label:"PP", value: "\(pp)")
                }
                if let accuracy = moveEntry.move.accuracy{
                    StatPill(label: "Acc", value: "\(accuracy)%")
                }

                Spacer()
                
                //learning method
                Text(moveEntry.move_learn_method == "level-up"
                     ? "Level \(moveEntry.level_learned_at)"
                     : "TM/HM")
                    .foregroundColor(.secondary)
            }
            
        }
        .padding()
        .background(Color.gray.opacity(0.1)) // Do the background of the color of the stat
        .cornerRadius(10)
    }
}

struct StatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack{
            Text(label)
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
