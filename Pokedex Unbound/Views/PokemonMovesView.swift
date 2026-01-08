import SwiftUI

struct PokemonMovesView: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon
    
    @State private var selectedLearnMethod: String = "All"
    
    var body: some View {
        ScrollView {
            VStack {
                if let details = vm.pokemonDetails {
                    
                    //Abilities
                    Text("Abilities")
                        .fontWeight(.bold)
                        .font(.title2)
                        .padding(.vertical, 6)
                    
                    VStack(spacing: 8){
                        let normalAbilities = details.abilities.filter { !$0.is_hidden}.sorted{$0.slot < $1.slot}
                        ForEach(normalAbilities, id: \.slot) { ability in
                            AbilityCard(ability: ability, isHidden: false)
                        }
                        
                        let hiddenAbilities = details.abilities.filter { $0.is_hidden}.sorted{$0.slot < $1.slot}
                        ForEach(hiddenAbilities, id: \.slot) { ability in
                            AbilityCard(ability: ability, isHidden: true)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Moves
                    Text("Moves")
                        .fontWeight(.bold)
                        .font(.title2)
                        .padding(.vertical, 6)
                    
                    Picker("Learn Method", selection: $selectedLearnMethod) {
                        Text("All").tag("All")
                        Text("Level Up").tag("level-up")
                        Text("TM/HM").tag("machine")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    let filteredMoves = selectedLearnMethod == "All"
                        ? details.moves
                        : details.moves.filter { $0.move_learn_method == selectedLearnMethod }
                    
                    let groupedMoves = Dictionary(grouping: filteredMoves) { $0.move_learn_method }
                    
                    if filteredMoves.isEmpty {
                        Text("Moves not found")
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    } else {
                        VStack(spacing: 12) {
                            if let levelUpMoves = groupedMoves["level-up"] {
                                MoveMethodAccordion(
                                    methodName: "Level Up",
                                    moves: levelUpMoves.sorted { $0.level_learned_at < $1.level_learned_at },
                                    icon: "arrow.up.circle.fill",
                                    color: .blue
                                )
                            }
                            
                            if let machineMoves = groupedMoves["machine"] {
                                MoveMethodAccordion(
                                    methodName: "TM/HM",
                                    moves: machineMoves.sorted { $0.move.name < $1.move.name },
                                    icon: "externaldrive.fill",
                                    color: .orange
                                )
                            }
                        }
                        .padding()
                    }
                } else {
                    ProgressView("Loading moves")
                        .padding(.top, 50)
                }
            }
        }
        .onAppear {
            print("MovesView vm object id: \(Unmanaged.passUnretained(vm).toOpaque())")
            print("PokemonMovesView onAppear - pokemonDetails is \(vm.pokemonDetails == nil ? "nil" : "loaded")")
        }
    }
}


struct MoveMethodAccordion: View {
    let methodName: String
    let moves: [DetailPokemon.MoveEntry]
    let icon: String
    let color: Color
    
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                    
                    Text(methodName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(moves.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color)
                        .cornerRadius(12)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(moves, id: \.uniqueID) { moveEntry in
                        MoveCardCompact(moveEntry: moveEntry)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}


struct MoveCardCompact: View {
    let moveEntry: DetailPokemon.MoveEntry
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Vue minimaliste
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(moveEntry.move.name.capitalized.replacingOccurrences(of: "-", with: " "))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let type = moveEntry.move.type {
                        Text(type.capitalized)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeColor(for: type))
                            .cornerRadius(6)
                    }
                    
                    Text(moveEntry.move_learn_method == "level-up"
                         ? "Lv.\(moveEntry.level_learned_at)"
                         : "TM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(typeColor(for: moveEntry.move.type ?? "normal").opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {

                    HStack(spacing: 12) {
                        if let power = moveEntry.move.power {
                            StatPillDetailed(label: "Power", value: "\(power)")
                        }
                        if let pp = moveEntry.move.pp {
                            StatPillDetailed(label: "PP", value: "\(pp)")
                        }
                        if let accuracy = moveEntry.move.accuracy {
                            StatPillDetailed(label: "Accuracy", value: "\(accuracy)%")
                        }
                        Spacer()
                    }
                }
                .padding(12)
                .background(typeColor(for: moveEntry.move.type ?? "normal").opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal, 4)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func typeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "normal": return Color.gray
        case "fire": return Color.red
        case "water": return Color.blue
        case "electric": return Color.yellow
        case "grass": return Color.green
        case "ice": return Color.cyan
        case "fighting": return Color.orange
        case "poison": return Color.purple
        case "ground": return Color.brown
        case "flying": return Color.blue.opacity(0.7)
        case "psychic": return Color.pink
        case "bug": return Color.green.opacity(0.7)
        case "rock": return Color.brown.opacity(0.7)
        case "ghost": return Color.purple.opacity(0.7)
        case "dragon": return Color.indigo
        case "dark": return Color.black
        case "steel": return Color.gray.opacity(0.7)
        case "fairy": return Color.pink.opacity(0.7)
        default: return Color.gray
        }
    }
}


struct StatPillDetailed: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .cornerRadius(8)
    }
}


// Older version, if necessary
struct StatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(label)
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(.semibold)
        }
    }
}


// Abilities
struct AbilityCard: View {
    let ability: DetailPokemon.AbilityEntry
    let isHidden: Bool
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: isHidden ? "eye.slash.fill" : "star.fill")
                        .font(.caption)
                        .foregroundStyle(isHidden ? .purple : .orange)
                    
                    Text(ability.ability.name.capitalized.replacingOccurrences(of: "-", with: " "))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if isHidden {
                        Text("Hidden")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.7))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(isHidden ? Color.purple.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(ability.ability.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isHidden ? Color.purple.opacity(0.05) : Color.orange.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal, 4)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
