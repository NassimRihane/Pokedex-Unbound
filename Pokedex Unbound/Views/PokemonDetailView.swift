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
        ScrollView{
            VStack(spacing: 20) {
                
                PokemonView(pokemon: pokemon)
                
                // Details from local files
                if let details = vm.pokemonDetails {
                    VStack(spacing: 10) {
                        HStack(spacing:20){
                            InfoCard(label:"English", value: "\(pokemon.name.capitalized)")
                            InfoCard(label:"Japanese", value: "\(details.nameJp)")
                            InfoCard(label:"French", value: "\(details.nameFr)")
                        }
                        HStack(spacing: 30){
                            InfoCard(label:"ID", value: "\(details.id)")
                            InfoCard(label:"Height", value: "\(vm.formatHW(value: details.height)) m")
                            InfoCard(label:"Weight", value: "\(vm.formatHW(value: details.weight)) kg")
                        }
                        // Display types
                        VStack(spacing: 5) {
                            Text("Types")
                                .font(.headline)
                            HStack(spacing: 5){
                                ForEach(details.types.sorted(by: { $0.slot < $1.slot }), id: \.type.name){ typeInfo in
                                    TypeImageView(typeName: typeInfo.type.name)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        
                        // Main stats
                        VStack(alignment: .leading, spacing: 12){
                            Text("Base Stats")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.bottom, 5)
                            
                            ForEach(details.stats, id: \.stat.name){ stat in
                                StatBarView(
                                    statName: stat.stat.name,
                                    value: stat.base_stat
                                )
                            }
                            
                            let total = details.stats.reduce(0) { $0 + $1.base_stat}
                            HStack{
                                Text("Total")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(total)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                } else{

                    ProgressView("Loading details...")
                }
            }
        //    .navigationTitle(pokemon.name.capitalized)
        //    .navigationBarTitleDisplayMode(.inline)
        //    .onAppear(){
        //        vm.pokemonDetails = nil
        //        vm.loadLocalDetails(for: pokemon)
        //    }
        //    .onDisappear{
        //        vm.pokemonDetails = nil
        //    }
        }
        //.navigationTitle(pokemon.name.capitalized)
        //.navigationBarTitleDisplayMode(.inline)
    }
}

struct PokemonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PokemonDetailView(pokemon: Pokemon.samplePokemon)
            .environmentObject(ViewModel())
    }
}



struct InfoCard: View{
    let label: String
    let value: String
    
    var body: some View{
        VStack(spacing: 4){
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.08).opacity(0.1))
        .cornerRadius(8)
    }
}



// Percentiles to fill stat bars

struct StatPercentiles {
    
    // Fixed threshold to avoid computing them every time
    static let hp: [Int] = [30, 45, 65, 80, 100, 110, 130]
    static let attack: [Int] = [35, 50, 75, 95, 115, 125, 140]
    static let defense: [Int] = [30, 50, 70, 85, 105, 115, 135]
    static let specialAttack: [Int] = [30, 45, 65, 90, 110, 120, 140]
    static let specialDefense: [Int] = [30, 50, 70, 85, 105, 115, 135]
    static let speed: [Int] = [25, 45, 70, 90, 108, 120, 140]
    
    // Get the percentiles
    static func getPercentiles(for statName: String) ->[Int]{
        switch statName.lowercased(){
        case "hp": return hp
        case "attack": return attack
        case "defense": return defense
        case "special-attack": return specialAttack
        case "special-defense": return specialDefense
        case "speed": return speed
        default: return [30, 50, 70, 90, 110, 125, 145]
        }
    }
}


struct StatBarView: View{
    let statName: String
    let value: Int
    
    // Max stat for index
    private var maxValue: Int {
        switch statName.lowercased() {
        case "hp": return 255               // Blissey
        case "attack": return 190           // Mega Mewtwo X
        case "defense": return 230          // Shuckle
        case "special-attack": return 194   // Mega Mewtwo Y
        case "special-defense": return 230  // Shuckle
        case "speed": return 180            // Deoxys Speed
        default:return 200
        }
    }
    
    // Name of stat
    private var displayName: String{
        switch statName.lowercased(){
        case "hp": return "HP"
        case "attack": return "Attack"
        case "defense": return "Defense"
        case "special-attacl": return "Sp. Atk"
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


struct TypeImageView: View{
    let typeName: String
    
    var body: some View{
        VStack(alignment: .leading, spacing: 4){
            if let typeImage = loadTypeImage(){
                Image(uiImage: typeImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            } else {
                // If image not found
                Text(typeName.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray)
                    .cornerRadius(12)
            }
        }
    }
    
    private func loadTypeImage() -> UIImage? {
        let fileName = typeName.lowercased()
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "png"),
           let imageData = try? Data(contentsOf: url),
           let uiImage = UIImage(data: imageData){
            return uiImage
        }
        
        print("Type \(fileName).png image not found")
        return nil
    }
}
