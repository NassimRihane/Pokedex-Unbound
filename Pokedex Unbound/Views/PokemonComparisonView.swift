//
//  PokemonComparisonView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 09/01/2026.
//

import SwiftUI

struct PokemonComparisonView: View {
    
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss

    @State private var leftPokemon: Pokemon?
    @State private var rightPokemon: Pokemon?
    @State private var leftSearchText: String = ""
    @State private var rightSearchText: String = ""
    @State private var leftDetails: DetailPokemon?
    @State private var rightDetails: DetailPokemon?
    @State private var isLeftSearching: Bool = false
    @State private var isRightSearching: Bool = false
    
    var leftFilteredPokemon: [Pokemon] {
        guard !leftSearchText.isEmpty else { return [] }
        let filtered = vm.pokemonList.filter { pokemon in
            pokemon.name.lowercased().contains(leftSearchText.lowercased())
        }
        return Array(filtered.prefix(10))
    }
    
    var rightFilteredPokemon: [Pokemon] {
        guard !rightSearchText.isEmpty else { return [] }
        let filtered = vm.pokemonList.filter { pokemon in
            pokemon.name.lowercased().contains(rightSearchText.lowercased())
        }
        return Array(filtered.prefix(10))
    }
    
    var body: some View {
        NavigationStack{
            GeometryReader{ geometry in
                HStack(spacing: 0) {
                    VStack {
                        PokemonComparisonSide(
                            pokemon: leftPokemon,
                            details: leftDetails,
                            searchText: $leftSearchText,
                            isSearching: $isLeftSearching,
                            filteredPokemon: leftFilteredPokemon,
                            onSelect: { pokemon in
                                leftPokemon = pokemon
                                leftSearchText = ""
                                isLeftSearching = false
                                loadDetails(for: pokemon, side: .left)
                            },
                            onClear: {
                                leftPokemon = nil
                                leftDetails = nil
                                leftSearchText = ""
                            }
                        )
                    }
                    .frame(width: geometry.size.width / 2)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                    
                    VStack {
                        PokemonComparisonSide(
                            pokemon: rightPokemon,
                            details: rightDetails,
                            searchText: $rightSearchText,
                            isSearching: $isRightSearching,
                            filteredPokemon: rightFilteredPokemon,
                            onSelect: { pokemon in
                                rightPokemon = pokemon
                                rightSearchText = ""
                                isRightSearching = false
                                loadDetails(for: pokemon, side: .right)
                            },
                            onClear: {
                                rightPokemon = nil
                                rightDetails = nil
                                rightSearchText = ""
                            }
                        )
                    }
                    .frame(width: geometry.size.width / 2)
                }
            }
            .navigationTitle("Pokemon Comparison")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func loadDetails(for pokemon: Pokemon, side: ComparisonSide) {
        let index = vm.getPokemonIndex(pokemon: pokemon)
        let formattedIndex = String(format: "%03d", index)
        let fileName = "\(formattedIndex)_\(pokemon.name.lowercased())"
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                let details = try JSONDecoder().decode(DetailPokemon.self, from: data)
                if side == .left {
                    leftDetails = details
                } else {
                    rightDetails = details
                }
            } catch {
                print("Decoding error for \(fileName): \(error)")
            }
        }
    }
}


enum ComparisonSide {
    case left, right
}

struct PokemonComparisonSide: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon?
    let details: DetailPokemon?
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let filteredPokemon: [Pokemon]
    let onSelect: (Pokemon) -> Void
    let onClear: () -> Void
    
    var body: some View {
        ScrollView{
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search Pokemon", text: $searchText)
                            .textFieldStyle(.plain)
                            .onTapGesture {
                                isSearching = true
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                isSearching = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 12)
                    
                    if isSearching && !filteredPokemon.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(filteredPokemon) { pkmn in
                                Button(action: {
                                    onSelect(pkmn)
                                }) {
                                    HStack(spacing: 8) {
                                        if let spriteImage = loadLocalSprite(for: pkmn) {
                                            Image(uiImage: spriteImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                        }
                                        
                                        Text("#\(String(format: "%03d", vm.getPokemonIndex(pokemon: pkmn)))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text(pkmn.name.capitalized)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.05))
                                }
                                
                                if pkmn.id != filteredPokemon.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                    }
                }
                
                if let pokemon = pokemon {
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Button(action: onClear){
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        
                        if let spriteImage = loadLocalSprite(for: pokemon) {
                            Image(uiImage: spriteImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                        }
                        
                        VStack(spacing: 4) {
                            Text("#\(String(format: "%03d", vm.getPokemonIndex(pokemon: pokemon)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(pokemon.name.capitalized)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        if let details = details {
                            VStack(spacing: 12) {
                                HStack(spacing: 5) {
                                    ForEach(details.types.sorted(by: { $0.slot < $1.slot }), id: \.type.name) { typeInfo in
                                        TypeImageView(typeName: typeInfo.type.name)
                                            .frame(height: 35)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(details.stats, id: \.stat.name) { stat in
                                        CompactStatBarView(
                                            statName: stat.stat.name,
                                            value: stat.base_stat
                                        )
                                    }
                                    
                                    let total = details.stats.reduce(0) { $0 + $1.base_stat }
                                    HStack {
                                        Text("Total")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Text("\(total)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(12)
                                .backgroundStyle(Color.gray.opacity(0.08))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal, 12)
                        } else {
                            ProgressView()
                                .padding()
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray.opacity(0.3))
                            .padding(.top, 100)
                        
                        Text("Select a Pokemon")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.top, 12)
        }
    }
    
    private func loadLocalSprite(for pokemon: Pokemon) -> UIImage? {
        let index = vm.getPokemonIndex(pokemon: pokemon)
        let formattedIndex = String(format: "%03d", index)
        let fileName = "\(formattedIndex)_\(pokemon.name.lowercased())"
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "png"),
           let imageData = try? Data(contentsOf: url),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        return nil
    }
}


struct CompactStatBarView: View{
    let statName: String
    let value: Int
        
    // Name of stat
    private var displayName: String{
        switch statName.lowercased(){
        case "hp": return "HP"
        case "attack": return "Attack"
        case "defense": return "Defense"
        case "special-attack": return "Sp. Atk"
        case "special-defense": return "Sp. Def"
        case "speed": return "Speed"
        default: return statName.capitalized
        }
    }
    
    
    // Find the percentile to which the stat belong
    private var percentile: Double{
        let thresholds = StatPercentiles.getPercentiles(for: statName)
        
        // Percentile 10
        if value <= thresholds[0]{
            return Double(value) / Double(thresholds[0]) * 0.1
        }
        
        // Percentile 10 to 25
        else if value <= thresholds[1]{
            let range = Double(thresholds[1] - thresholds[0])
            let position = Double(value - thresholds[0])
            return 0.1 + (position / range) * 0.15
        }
        
        // 25 to 50
        else if value <= thresholds[2]{
            let range = Double(thresholds[2] - thresholds[1])
            let position = Double(value - thresholds[1])
            return 0.25 + (position / range) * 0.25
        }
        
        // 50 to 75
        else if value <= thresholds[3]{
            let range = Double(thresholds[3] - thresholds[2])
            let position = Double(value - thresholds[2])
            return 0.5 + (position / range) * 0.25
        }
        
        // 75 to 90
        else if value <= thresholds[4]{
            let range = Double(thresholds[4] - thresholds[3])
            let position = Double(value - thresholds[3])
            return 0.75 + (position / range) * 0.15
        }
        
        // 90 to 95
        else if value <= thresholds[5]{
            let range = Double(thresholds[5] - thresholds[4])
            let position = Double(value - thresholds[4])
            return 0.9 + (position / range) * 0.05
        }
        
        // 95 to 99
        else if value <= thresholds[6]{
            let range = Double(thresholds[6] - thresholds[5])
            let position = Double(value - thresholds[5])
            return 0.95 + (position / range) * 0.04
        }
        
        // Over 99 (top 1%)
        else{
            return min(0.99 + (Double(value - thresholds[6]) / 100.0) * 0.01, 1.0)
        }
    }
    
    
    // Color of stat
    private var barColor: Color{
       
        switch percentile{
        case 0..<0.25:
            return .red
        case 0.25..<0.5:
            return .orange
        case 0.5..<0.75:
            return .yellow
        case 0.75..<0.9:
            return .green
        case 0.9..<0.95:
            return .blue
        default:
            return .purple
        }
    }
    
    // Label to display stat quality
    private var rankLabel: String{
        let percent = Int(percentile * 100)
        switch percentile {
        case 0..<0.25: return "Bad"
        case 0.25..<0.5: return "Average"
        case 0.5..<0.75: return "Good"
        case 0.75..<0.9: return "Great"
        case 0.9..<0.95: return "Excellent"
        default: return "Top \(100 - percent)%"
        }
    }
    
    
    var body: some View{
        VStack(alignment: .leading, spacing: 4){
            HStack{
                Text(displayName)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 80, alignment: .leading)
                
                Text("\(value)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .frame(width: 40, alignment: .trailing)
                
                GeometryReader{ geometry in
                    ZStack(alignment: .leading){
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor)
                            .frame(
                                width: geometry.size.width * CGFloat(percentile),
                                height: 20
                            )
                            .animation(.easeInOut(duration: 0.5), value: value)
                    }
                }
                
                Text(rankLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(barColor)
                    .frame(width: 60, alignment: .leading)
            }
            .frame(height: 20)
        }
    }
}

#Preview {
    PokemonComparisonView()
}
