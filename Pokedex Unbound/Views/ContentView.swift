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

struct ContentView: View {
    @StateObject var vm = ViewModel()
    @State private var displayMode: DisplayMode = .large
    
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                switch displayMode {
                case .large, .small:
                    LazyVGrid(columns: columns, spacing: displayMode == .large ? 10 : 5) {
                        ForEach(vm.filteredPokemon) { pokemon in
                            NavigationLink(destination: PokemonTabView(pokemon: pokemon)) {
                                if displayMode == .large {
                                    PokemonView(pokemon: pokemon)
                                } else {
                                    PokemonViewSmall(pokemon: pokemon)
                                }
                            }
                        }
                    }
                    .animation(.easeIn(duration: 0.3), value: vm.filteredPokemon.count)
                    .padding(.horizontal)
                    
                case .minimal:
                    LazyVStack(spacing: 0) {
                        ForEach(vm.filteredPokemon) { pokemon in
                            NavigationLink(destination: PokemonTabView(pokemon: pokemon)) {
                                PokemonViewMinimal(pokemon: pokemon)
                            }
                        }
                    }
                    .animation(.easeIn(duration: 0.3), value: vm.filteredPokemon.count)
                }
            }
            .navigationTitle("PokemonUI")
            .searchable(text: $vm.searchText)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // To change display mode
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

#Preview {
    ContentView()
}
