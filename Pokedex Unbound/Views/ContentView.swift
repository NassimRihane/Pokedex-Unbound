//
//  ContentView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 27/10/2025.
//

import SwiftUI



enum DisplayMode: String, CaseIterable {
    case large = "Large"
    case small = "Small"
    case minimal = "Minimal"
    
    var icon: String {
        switch self {
        case .large: return "square.grid.2x2"
        case .small: return "square.grid.3x3"
        case .minimal: return "list.bullet"
        }
    }
}



enum PokemonType: String, CaseIterable, Identifiable{
    case normal, fire, water, electric, grass, ice, fighting, poison, ground, flying, psychic, bug, rock, ghost, dragon, dark, steel, fairy
    
    var id: String{self.rawValue}
    
    var displayName: String{
        return self.rawValue.capitalized
    }
    
    var color: Color{
        switch self{
        case .normal: return Color.gray
        case .fire: return Color.red
        case .water: return Color.blue
        case .electric: return Color.yellow
        case .grass: return Color.green
        case .ice: return Color.cyan
        case .fighting: return Color.orange
        case .poison: return Color.purple
        case .ground: return Color.brown
        case .flying: return Color.blue.opacity(0.7)
        case .psychic: return Color.pink
        case .bug: return Color.green.opacity(0.7)
        case .rock: return Color.brown.opacity(0.7)
        case .ghost: return Color.purple.opacity(0.7)
        case .dragon: return Color.indigo
        case .dark: return Color.black
        case .steel: return Color.gray.opacity(0.7)
        case .fairy: return Color.pink.opacity(0.7)
        }
    }
}

struct ContentView: View {
    @StateObject var vm = ViewModel()
    @State private var displayMode: DisplayMode = .large
    @State private var selectedTypes: Set<PokemonType> = []
    @State private var showFilterSheet = false
    
    // Adaptative columns according to display modes
    private var columns: [GridItem] {
        switch displayMode {
        case .large:
            return [GridItem(.adaptive(minimum: 150))]
        case .small:
            return [GridItem(.adaptive(minimum: 80))]
        case .minimal:
            return [GridItem(.flexible())]
        }
    }
    
    private var filteredByType: [Pokemon]{
        let searchFilterd = vm.filteredPokemon
        
        if selectedTypes.isEmpty{
            return searchFilterd
        }
        
        return searchFilterd.filter{ pokemon in
            let pokemonTypes = vm.getPokemonTypes(for: pokemon)
            let selectedTypeNames = Set(selectedTypes.map{$0.rawValue})
            
            return selectedTypeNames.isSubset(of: pokemonTypes)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                if !selectedTypes.isEmpty{
                    ActiveFiltersView(selectedTypes: $selectedTypes)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                switch displayMode {
                case .large, .small:
                    LazyVGrid(columns: columns, spacing: displayMode == .large ? 10 : 5) {
                        ForEach(filteredByType) { pokemon in
                            NavigationLink(destination: PokemonTabView(pokemon: pokemon)) {
                                if displayMode == .large {
                                    PokemonView(pokemon: pokemon)
                                } else {
                                    PokemonViewSmall(pokemon: pokemon)
                                }
                            }
                        }
                    }
                    .animation(.easeIn(duration: 0.3), value: filteredByType.count)
                    .padding(.horizontal)
                    
                case .minimal:
                    LazyVStack(spacing: 0) {
                        ForEach(filteredByType) { pokemon in
                            NavigationLink(destination: PokemonTabView(pokemon: pokemon)) {
                                PokemonViewMinimal(pokemon: pokemon)
                            }
                        }
                    }
                    .animation(.easeIn(duration: 0.3), value: filteredByType.count)
                }
            }
            .navigationTitle("PokemonUI")
            .searchable(text: $vm.searchText)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                            
                            if !selectedTypes.isEmpty {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Text("\(selectedTypes.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                
                
                // On the right: change display mode
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(DisplayMode.allCases, id: \.self) { mode in
                            Button(action: {
                                withAnimation {
                                    displayMode = mode
                                }
                            }) {
                                Label(mode.rawValue, systemImage: mode.icon)
                                if displayMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: displayMode.icon)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheet(selectedTypes: $selectedTypes)
            }
        }
        .environmentObject(vm)
    }
}


struct PokemonViewSmall: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon
    let dimensions: Double = 70
    
    var body: some View {
        VStack(spacing: 4) {
            if let spriteImage = loadLocalSprite(for: pokemon) {
                Image(uiImage: spriteImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: dimensions, height: dimensions)
            } else {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: dimensions, height: dimensions)
                    Text("?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.gray)
                }
            }
            
            Text(pokemon.name.capitalized)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .lineLimit(1)
                .padding(.bottom, 8)
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


struct PokemonViewMinimal: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon
    
    var body: some View {
        HStack(spacing: 12) {
            // Miniature sprite
            if let spriteImage = loadLocalSprite(for: pokemon) {
                Image(uiImage: spriteImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("?")
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    )
            }
            
            // ID and name
            HStack {
                Text("#\(String(format: "%03d", vm.getPokemonIndex(pokemon: pokemon)))")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text(pokemon.name.capitalized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .contentShape(Rectangle())
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

// Filter section

struct FilterSheet: View {
    @Binding var selectedTypes: Set<PokemonType>
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 20){
                    VStack(alignment: .leading, spacing: 12){
                        Text("Types")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select up to 2 types")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10){
                            ForEach(PokemonType.allCases){ type in
                                TypeFilterButton(type: type,
                                                 isSelected: selectedTypes.contains(type),
                                                 action: {
                                                    toggleType(type)
                                                }
                                )
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading){
                    Button("Clear"){
                        selectedTypes.removeAll()
                    }
                    .disabled(selectedTypes.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Done"){
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleType(_ type: PokemonType){
        if selectedTypes.contains(type){
            selectedTypes.remove(type)
        } else if selectedTypes.count < 2 {
            selectedTypes.insert(type)
        }
    }
}



struct TypeFilterButton: View {
    let type: PokemonType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View{
        Button(action: action) {
            HStack{
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold: .regular)
                
                if isSelected{
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white: type.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? type.color : type.color.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(type.color, lineWidth: isSelected ? 2: 1)
            )
        }
    }
}


struct ActiveFiltersView: View{
    @Binding var selectedTypes: Set<PokemonType>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 10) {
                ForEach(Array(selectedTypes).sorted(by: { $0.rawValue < $1.rawValue })) { type in
                    HStack(spacing: 4) {
                        Text(type.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Button(action: {
                            selectedTypes.remove(type)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(type.color)
                    .cornerRadius(12)
                }
            }
        }
    }
}


#Preview {
    ContentView()
}

