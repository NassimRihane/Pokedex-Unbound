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
    
    // Order the display modes for the gesture
    static let ordered: [DisplayMode] = [.minimal, .small, .large]
    
    func next() -> DisplayMode{
        let idx = Self.ordered.firstIndex(of: self) ?? 0
        let nextIdx = min(idx + 1, Self.ordered.count - 1)
        return Self.ordered[nextIdx]
    }
    
    func previous() -> DisplayMode{
        let idx = Self.ordered.firstIndex(of: self) ?? 0
        let prevIdx = max(idx - 1, 0)
        return Self.ordered[prevIdx]
    }
}


// Gesture to navigate between the modes
struct MagnifyGestureView<Content: View>: View {
    // Threshold to decide what is a gesture
    private let threshold: CGFloat
    private let onPinchIn: () -> Void
    private let onPinchOut: () -> Void
    private let content: Content
    
    @State private var currentScale: CGFloat = 1.0
    @State private var isGestureActive: Bool = false // UX improvement
    
    init(
        threshold: CGFloat = 0.15,
        onPinchIn: @escaping () -> Void,
        onPinchOut: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.threshold = threshold
        self.onPinchIn = onPinchIn
        self.onPinchOut = onPinchOut
        self.content = content()
    }
    
    var body: some View {
        content
            .simultaneousGesture(
                MagnificationGesture(minimumScaleDelta: 0.0)
                    .onChanged { value in
                        currentScale = value
                        if abs(value-1.0) > 0.08 {
                            isGestureActive = true
                        }
                    }
                    .onEnded { final in
                        let delta = final - 1.0
                        if isGestureActive && abs(delta) > threshold{
                            if delta > 0 {
                                onPinchOut()
                            } else {
                                onPinchIn()
                            }
                        }
                        currentScale = 1.0
                        isGestureActive = false
                    }
            )
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

enum PokemonGeneration: Int, CaseIterable, Identifiable{
    case i = 1, ii, iii, iv, v, vi, vii, viii
    
    var id: Int{self.rawValue}
    
    var displayName: String{
        switch self{
        case .i: return "I"
        case .ii: return "II"
        case .iii: return "III"
        case .iv: return "IV"
        case .v: return "V"
        case .vi: return "VI"
        case .vii: return "VII"
        case .viii: return "VIII"
        }
    }
    
    var idRange: ClosedRange<Int>{
        switch self{
        case .i: return 1...151
        case .ii: return 152...251
        case .iii: return 252...386
        case .iv: return 387...494
        case .v: return 495...649
        case .vi: return 650...721
        case .vii: return 722...809
        case .viii: return 810...905
        }
    }
    
    var color: Color{
        switch self{
        case .i: return Color.red
        case .ii: return Color.orange
        case .iii: return Color.green
        case .iv: return Color.blue
        case .v: return Color.purple
        case .vi: return Color.pink
        case .vii: return Color.cyan
        case .viii: return Color.indigo
        }
    }
    
    static func from(pokemonId: Int) -> PokemonGeneration? {
        return PokemonGeneration.allCases.first {$0.idRange.contains(pokemonId)}
    }
}


enum SortMethod: Equatable, Identifiable{
    case id
    case name
    case hp(ascending: Bool)
    case attack(ascending: Bool)
    case defense(ascending: Bool)
    case specialAttack(ascending: Bool)
    case specialDefense(ascending: Bool)
    case speed(ascending: Bool)
    case total(ascending: Bool)
    
    var id: String{
        switch self{
        case .id: return "id"
        case .name: return "name"
        case .hp(let asc): return "hp_\(asc)"
        case .attack(let asc): return "attack_\(asc)"
        case .defense(let asc): return "defense_\(asc)"
        case .specialAttack(let asc): return "specialAttack_\(asc)"
        case .specialDefense(let asc): return "specialDefense_\(asc)"
        case .speed(let asc): return "speed_\(asc)"
        case .total(let asc): return "total_\(asc)"
        }
    }
    
    var displayName: String{
        switch self{
        case .id: return "ID"
        case .name: return "Name"
        case .hp(let asc): return "HP (\(asc ? "Lowest" : "Highest") First)"
        case .attack(let asc): return "Attack (\(asc ? "Lowest" : "Highest") First)"
        case .defense(let asc): return "Defense (\(asc ? "Lowest" : "Highest") First)"
        case .specialAttack(let asc): return "Sp. Atk (\(asc ? "Lowest" : "Highest") First)"
        case .specialDefense(let asc): return "Sp. Def (\(asc ? "Lowest" : "Highest") First)"
        case .speed(let asc): return "Speed (\(asc ? "Lowest" : "Highest") First)"
        case .total(let asc): return "Total Stats (\(asc ? "Lowest" : "Highest") First)"
        }
    }
    
    var shortName: String{
        switch self{
        case .id: return "ID"
        case .name: return "Name"
        case .hp: return "HP"
        case .attack: return "Attack"
        case .defense: return "Defense"
        case .specialAttack: return "Sp. Atk"
        case .specialDefense: return "Sp. Def"
        case .speed: return "Speed"
        case .total: return "Total"
        }
    }
    
    var icon: String{
        switch self{
        case .id: return "number"
        case .name: return "textformat.abc"
        case .hp: return "heart.fill"
        case .attack: return "bolt.fill"
        case .defense: return "shield.fill"
        case .specialAttack: return "sparkles"
        case .specialDefense: return "shield.lefthalf.filled"
        case .speed: return "hare.fill"
        case .total: return "chart.bar.fill"
        }
    }
}


enum SortCategory: String, CaseIterable{
    case general = "General"
    case stats = "Stats"
    
    func methods() -> [SortMethod]{
        switch self {
        case .general:
            return [.id, .name]
        case .stats:
            return [
                .hp(ascending: false),
                .hp(ascending: true),
                .attack(ascending: false),
                .attack(ascending: true),
                .defense(ascending: false),
                .defense(ascending: true),
                .specialAttack(ascending: false),
                .specialAttack(ascending: true),
                .specialDefense(ascending: false),
                .specialDefense(ascending: true),
                .speed(ascending: false),
                .speed(ascending: true),
                .total(ascending: false),
                .total(ascending: true)
            ]
        }
    }
}


struct ContentView: View {
    @EnvironmentObject var captureManager: CaptureManager
    @StateObject var vm = ViewModel()
    @State private var displayMode: DisplayMode = .large
    @State private var selectedTypes: Set<PokemonType> = []
    @State private var selectedGens: Set<PokemonGeneration> = []
    @State private var statFilters = StatFilters()
    @State private var sortMethod: SortMethod = .id
    @State private var captureFilters: [PokemonGame: CaptureFilterState] = [:]
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
    
    private var filteredAndSortedPokemon: [Pokemon]{
        var filtered = vm.filteredPokemon
        
        if !selectedTypes.isEmpty{
            filtered = filtered.filter{ pokemon in
                let pokemonTypes = vm.getPokemonTypes(for: pokemon)
                let selectedTypeNames = Set(selectedTypes.map{$0.rawValue})
                return selectedTypeNames.isSubset(of: pokemonTypes)
            }
        }
        
        if !selectedGens.isEmpty{
            filtered = filtered.filter{ pokemon in
                let pokemonId = vm.extractIDFromURL(pokemon.url)
                return selectedGens.contains{ gen in
                    gen.idRange.contains(pokemonId)
                }
            }
        }
        
        if statFilters.hasActiveFilters{
            filtered = filtered.filter{ pokemon in
                let stats = vm.getPokemonStats(for: pokemon)
                
                // Check if the stat filter is active
                if statFilters.hp > 0 && stats.hp < statFilters.hp {return false}
                if statFilters.attack > 0 && stats.attack < statFilters.attack {return false}
                if statFilters.defense > 0 && stats.defense < statFilters.defense {return false}
                if statFilters.specialAttack > 0 && stats.specialAttack < statFilters.specialAttack {return false}
                if statFilters.specialDefense > 0 && stats.specialDefense < statFilters.specialDefense {return false}
                if statFilters.speed > 0 && stats.speed < statFilters.speed {return false}
                
                return true
            }
        }
        
        if !captureFilters.isEmpty{
            filtered = filtered.filter { pokemon in
                for (game, state) in captureFilters where state != .none{
                    let isCaught = captureManager.isCaught(pokemon.name, in: game)
                    
                    switch state{
                    case .caught: if !isCaught {return false}
                    case .notCaught: if isCaught {return false}
                    case .none: continue
                    }
                }
                return true
            }
        }
        
        return sortPokemon(filtered, by: sortMethod)
    }
    
    private func sortPokemon(_ pokemon: [Pokemon], by method: SortMethod) -> [Pokemon] {
        switch method {
        case .id:
            return pokemon.sorted {vm.extractIDFromURL($0.url) < vm.extractIDFromURL($1.url)}
            
        case .name:
            return pokemon.sorted {$0.name < $1.name}
            
        case .hp(let ascending):
            return pokemon.sorted{
                let stat1 = vm.getPokemonStats(for: $0).hp
                let stat2 = vm.getPokemonStats(for: $1).hp
                return ascending ? stat1 < stat2 : stat1 > stat2
            }
            
        case .attack(let ascending):
            return pokemon.sorted{
                let stat1 = vm.getPokemonStats(for: $0).attack
                let stat2 = vm.getPokemonStats(for: $1).attack
                return ascending ? stat1 < stat2 : stat1 > stat2
            }
            
        case .defense(let ascending):
            return pokemon.sorted{
                let stat1 = vm.getPokemonStats(for: $0).defense
                let stat2 = vm.getPokemonStats(for: $1).defense
                return ascending ? stat1 < stat2 : stat1 > stat2
            }
            
        case .specialAttack(let ascending):
            return pokemon.sorted{
                let stat1 = vm.getPokemonStats(for: $0).specialAttack
                let stat2 = vm.getPokemonStats(for: $1).specialAttack
                return ascending ? stat1 < stat2 : stat1 > stat2
            }
            
        case .specialDefense(let ascending):
            return pokemon.sorted{
                let stat1 = vm.getPokemonStats(for: $0).specialDefense
                let stat2 = vm.getPokemonStats(for: $1).specialDefense
                return ascending ? stat1 < stat2 : stat1 > stat2
            }
            
        case .speed(let ascending):
            return pokemon.sorted{
                let stat1 = vm.getPokemonStats(for: $0).speed
                let stat2 = vm.getPokemonStats(for: $1).speed
                return ascending ? stat1 < stat2 : stat1 > stat2
            }
            
        case .total(let ascending):
            return pokemon.sorted{
                let stat1 = vm.getPokemonStats(for: $0)
                let stat2 = vm.getPokemonStats(for: $1)
                let total1 = stat1.hp + stat1.attack + stat1.defense + stat1.specialAttack + stat1.specialDefense + stat1.speed
                let total2 = stat2.hp + stat2.attack + stat2.defense + stat2.specialAttack + stat2.specialDefense + stat2.speed
                return ascending ? total1 < total2 : total1 > total2
            }
        }
    }
    
    var body: some View {
        MagnifyGestureView(
            threshold: 0.12,
            onPinchIn: {
                // Gets smaller
                withAnimation(.snappy) {
                    displayMode = displayMode.previous()
                }
            },
            onPinchOut: {
                // Gets bigger
                withAnimation(.snappy) {
                    displayMode = displayMode.next()
                }
            }
        ) {
            NavigationStack {
                ScrollView {
                    if !selectedTypes.isEmpty || !selectedGens.isEmpty || statFilters.hasActiveFilters || !captureFilters.isEmpty {
                        ActiveFiltersView(
                            selectedTypes: $selectedTypes,
                            selectedGens: $selectedGens,
                            statFilters: $statFilters,
                            captureFilters: $captureFilters
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    if sortMethod != .id {
                        HStack {
                            Image(systemName: sortMethod.icon)
                                .font(.caption)
                            Text("Sorted by: \(sortMethod.shortName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    
                    switch displayMode {
                    case .large, .small:
                        LazyVGrid(columns: columns, spacing: displayMode == .large ? 10 : 5) {
                            ForEach(filteredAndSortedPokemon) { pokemon in
                                NavigationLink(destination: PokemonTabView(pokemon: pokemon)) {
                                    if displayMode == .large {
                                        PokemonView(pokemon: pokemon)
                                    } else {
                                        PokemonViewSmall(pokemon: pokemon)
                                    }
                                }
                            }
                        }
                        .animation(.easeIn(duration: 0.3), value: filteredAndSortedPokemon.count)
                        .padding(.horizontal)
                        
                    case .minimal:
                        LazyVStack(spacing: 0) {
                            ForEach(filteredAndSortedPokemon) { pokemon in
                                NavigationLink(destination: PokemonTabView(pokemon: pokemon)) {
                                    PokemonViewMinimal(pokemon: pokemon)
                                }
                            }
                        }
                        .animation(.easeIn(duration: 0.3), value: filteredAndSortedPokemon.count)
                    }
                }
                .navigationTitle("Pokedex")
                .searchable(text: $vm.searchText)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showFilterSheet = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.title3)
                                
                                let activeCaptureFilters = captureFilters.values.filter { $0 != .none }.count
                                let totalFilters = selectedTypes.count + selectedGens.count + statFilters.activeCount + activeCaptureFilters
                                
                                if totalFilters > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Text("\(totalFilters)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                    
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
                    FilterSheet(
                        selectedTypes: $selectedTypes,
                        selectedGens: $selectedGens,
                        statFilters: $statFilters,
                        sortMethod: $sortMethod,
                        captureFilters: $captureFilters
                    )
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
                    .frame(width: 30, height: 30)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
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
        .padding(.vertical, 2)
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
    @Binding var selectedGens: Set<PokemonGeneration>
    @Binding var statFilters: StatFilters
    @Binding var sortMethod: SortMethod
    @Binding var captureFilters: [PokemonGame: CaptureFilterState]
    @Environment(\.dismiss) var dismiss
    
    @State private var showSortSheet = false
    
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 20){
                    
                    // Sorting menu
                    VStack(alignment: .leading, spacing: 12){
                        Text("Sort")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Button(action: {showSortSheet = true}){
                            HStack{
                                Image(systemName: sortMethod.icon)
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 2){
                                    Text("Sort by")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(sortMethod.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    Divider().padding(.vertical, 10)

                    
                    // Type filter display
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
                    
                    Divider().padding(.vertical, 10)
                    
                    
                    // Generation filter display
                    VStack(alignment: .leading, spacing: 12){
                        Text("Generations")
                            .font(.title2)
                            .fontWeight(.bold)
            
                        Text("Select the generations to filter")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10){
                            ForEach(PokemonGeneration.allCases, id: \.id){ generation in
                                GenerationFilterButton(generation: generation,
                                                 isSelected: selectedGens.contains(generation),
                                                 action:{
                                                    toggleGeneration(generation)
                                                }
                                )
                            }
                        }
                    }
                    
                    Divider().padding(.vertical, 10)
                    
                    // Stat filter sliders display
                    VStack( alignment: .leading, spacing: 12){
                        Text("Minimum Stats")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Filter by minimum base stats (0 = no filter)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        //Sliders
                        StatSlider(
                            label: "HP",
                            value: $statFilters.hp,
                            range: 0...255,
                            color: .green
                        )
                        
                        StatSlider(
                            label: "Attack",
                            value: $statFilters.attack,
                            range: 0...190,
                            color: .red
                        )
                        
                        StatSlider(
                            label: "Defense",
                            value: $statFilters.defense,
                            range: 0...230,
                            color: .yellow
                        )
                        
                        StatSlider(
                            label: "Sp. Atk",
                            value: $statFilters.specialAttack,
                            range: 0...194,
                            color: .blue
                        )
                        
                        StatSlider(
                            label: "Sp. Def",
                            value: $statFilters.specialDefense,
                            range: 0...230,
                            color: .orange
                        )
                        
                        StatSlider(
                            label: "Speed",
                            value: $statFilters.speed,
                            range: 0...180,
                            color: .purple
                        )
                        
                        if statFilters.hasActiveFilters{
                            HStack{
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Filtering \(statFilters.activeCount) stat(s)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    Divider().padding(.vertical, 10)
                    
                    VStack(alignment: .leading, spacing: 12){
                        Text("Captures")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8){
                            Text("Filter by capture status")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12){
                                Label("Not filtered", systemImage: "circle")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                
                                Label("Caught", systemImage: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                
                                Label("Not Caught", systemImage: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        ForEach(0..<9, id: \.self) { gen in
                            let gamesInGen = PokemonGame.allCases.filter { $0.generation == gen }

                            if !gamesInGen.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(gen == 0 ? "Fan Games" : "Generation \(gen)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)

                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                                        ForEach(gamesInGen) { game in
                                            CaptureFilterButton(
                                                game: game,
                                                state: captureFilters[game] ?? .none,
                                                action: {
                                                    toggleCaptureFilter(for: game)
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Filters & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading){
                    Button("Clear"){
                        selectedTypes.removeAll()
                        selectedGens.removeAll()
                        statFilters.reset()
                        sortMethod = .id
                    }
                    .disabled(selectedTypes.isEmpty && selectedGens.isEmpty && !statFilters.hasActiveFilters)
                }
                
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Done"){
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSortSheet){
                SortSelectionSheet(sortMethod: $sortMethod)
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
    
    private func toggleGeneration(_ gen: PokemonGeneration){
        if selectedGens.contains(gen){
            selectedGens.remove(gen)
        } else{
            selectedGens.insert(gen)
        }
    }
    
    private func toggleCaptureFilter(for game: PokemonGame){
        var state = captureFilters[game] ?? .none
        state.next()
        
        if state == .none {
            captureFilters.removeValue(forKey: game)
        } else {
            captureFilters[game] = state
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


struct GenerationFilterButton: View {
    let generation: PokemonGeneration
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View{
        Button(action: action) {
            HStack{
                Text(generation.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold: .regular)
                
                if isSelected{
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white: generation.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? generation.color : generation.color.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(generation.color, lineWidth: isSelected ? 2: 1)
            )
        }
    }
}



struct ActiveFiltersView: View{
    @Binding var selectedTypes: Set<PokemonType>
    @Binding var selectedGens: Set<PokemonGeneration>
    @Binding var statFilters: StatFilters
    @Binding var captureFilters: [PokemonGame: CaptureFilterState]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 10) {
                
                ForEach(Array(selectedTypes).sorted(by: { $0.rawValue < $1.rawValue })) { type in
                    FilterBadge(
                        text: type.displayName,
                        color: type.color,
                        onRemove: {
                            selectedTypes.remove(type)
                        }
                    )
                }
                
                ForEach(Array(selectedGens).sorted(by: {$0.rawValue < $1.rawValue}), id: \.id){ gen in
                    FilterBadge(
                        text: gen.displayName,
                        color: gen.color,
                        onRemove: {
                            selectedGens.remove(gen)
                        }
                    )
                }
                
                if statFilters.hp > 0 {
                    FilterBadge(
                        text: "HP≥\(statFilters.hp)",
                        color: .green,
                        onRemove: { statFilters.hp = 0 }
                    )
                }
                if statFilters.attack > 0 {
                    FilterBadge(
                        text: "Atk≥\(statFilters.attack)",
                        color: .red,
                        onRemove: { statFilters.attack = 0 }
                    )
                }
                if statFilters.defense > 0 {
                    FilterBadge(
                        text: "Def≥\(statFilters.defense)",
                        color: .yellow,
                        onRemove: { statFilters.defense = 0 }
                    )
                }
                if statFilters.specialAttack > 0 {
                    FilterBadge(
                        text: "SpA≥\(statFilters.specialAttack)",
                        color: .blue,
                        onRemove: { statFilters.specialAttack = 0 }
                    )
                }
                if statFilters.specialDefense > 0 {
                    FilterBadge(
                        text: "SpD≥\(statFilters.specialDefense)",
                        color: .orange,
                        onRemove: { statFilters.specialDefense = 0 }
                    )
                }
                if statFilters.speed > 0 {
                    FilterBadge(
                        text: "Spd≥\(statFilters.speed)",
                        color: .purple,
                        onRemove: { statFilters.speed = 0 }
                    )
                }
            }
        }
    }
}

struct FilterBadge: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4){
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
            
            Button(action: onRemove){
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color)
        .cornerRadius(12)
    }
}


// Stat filter
struct StatFilters{
    var hp: Int = 0
    var attack: Int = 0
    var defense: Int = 0
    var specialAttack: Int = 0
    var specialDefense: Int = 0
    var speed: Int = 0
    
    // Check if a filter is active and how many are
    var hasActiveFilters: Bool{
        return hp > 0 || attack > 0 || defense > 0 || specialAttack > 0 || specialDefense > 0 || speed > 0
    }
    
    var activeCount: Int{
        var count = 0
        if hp > 0 {count += 1}
        if attack > 0 {count += 1}
        if defense > 0 {count += 1}
        if specialAttack > 0 {count += 1}
        if specialDefense > 0 {count += 1}
        if speed > 0 {count += 1}
        return count
    }
    
    mutating func reset(){
        hp = 0
        attack = 0
        defense = 0
        specialAttack = 0
        specialDefense = 0
        speed = 0
    }
}


struct StatSlider: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let color: Color
    
    var body: some View{
        VStack(spacing: 6){
            HStack{
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 70, alignment: .leading)
                
                Text("\(value)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(value > 0 ? color : .secondary)
                    .frame(width: 40, alignment: .trailing)
                
                Slider(
                    value: Binding(
                        get: { Double(value)},
                        set: { value = Int($0)}
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: 5
                )
                .tint(value > 0 ? color : .gray.opacity(0.3))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading){
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    if value > 0{
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(
                                width: geometry.size.width * CGFloat(value) / CGFloat(range.upperBound),
                                height: 4
                            )
                    }
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}


// Sort selection
struct SortSelectionSheet: View{
    @Binding var sortMethod: SortMethod
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            List{
                ForEach(SortCategory.allCases, id: \.self){ category in
                    Section(header: Text(category.rawValue)){
                        let methods = category.methods()
                        ForEach(methods, id: \.id) { method in
                            Button(action: {
                                sortMethod = method
                                dismiss()
                            }) {
                                HStack{
                                    Image(systemName: method.icon)
                                        .foregroundStyle(.blue)
                                        .frame(width: 24)
                                    
                                    Text(method.displayName)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    if sortMethod == method {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Cancel"){
                        dismiss()
                    }
                }
            }
        }
    }
}


struct CaptureFilterButton: View{
    let game: PokemonGame
    let state: CaptureFilterState
    let action: () -> Void
    
    var body: some View{
        Button(action: action){
            HStack(spacing: 8){
                Circle()
                    .fill(game.color)
                    .frame(width: 8, height: 8)
                
                Text(game.displayName)
                    .font(.caption)
                    .fontWeight(state != .none ? .semibold : .regular)
                
                Spacer()
                
                Image(systemName: state.icon)
                    .font(.caption)
                    .foregroundStyle(state.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(state != .none ? state.color.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(state != .none ? state.color : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

enum CaptureFilterState: Equatable{
    case none       // not filtered
    case caught
    case notCaught
    
    // When the button is touched: notfiltered -> caught -> not caught
    mutating func next(){
        switch self{
        case .none: self = .caught
        case .caught: self = .notCaught
        case .notCaught: self = .none
        }
    }
    
    var icon: String{
        switch self{
        case .none: return "circle"
        case .caught: return "checkmark.circle.fill"
        case .notCaught: return "xmark.circle.fill"
        }
    }
    
    var color: Color{
        switch self{
        case .none: return .gray
        case .caught: return .green
        case .notCaught: return .red
        }
    }
}


#Preview {
    ContentView()
}

