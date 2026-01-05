//
//  PokemonCaptureView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 24/12/2025.
//

import SwiftUI
import Combine

enum PokemonGame: String, CaseIterable, Identifiable{
    case red, firered, ruby, blue, sapphire, yellow, gold, silver, crystal, emerald, leafgreen, diamond, pearl, platinum, heartgold, soulsilver, black, black2, white, white2, x, y, sun, moon, sword, shield, unbound
    case omegaRuby = "omega-ruby"
    case alphaSapphire = "alpha-sapphire"
    case ultraSun = "ultra-sun"
    case ultraMoon = "ultra-moon"
    
    var id: String{self.rawValue}
    
    var displayName: String{
        switch self{
        case .red: return "Red"
        case .firered: return "Fire Red"
        case .ruby: return "Ruby"
        case .omegaRuby: return "Omega Ruby"
        case .blue: return "Blue"
        case .sapphire: return "Sapphire"
        case .alphaSapphire: return "Alpha Sapphire"
        case .yellow: return "Yellow"
        case .gold: return "Gold"
        case .silver: return "Silver"
        case .crystal: return "Crystal"
        case .emerald: return "Emerald"
        case .leafgreen: return "Leaf Green"
        case .diamond: return "Diamond"
        case .pearl: return "Pearl"
        case .platinum: return "Platinum"
        case .heartgold: return "Heart Gold"
        case .soulsilver: return "Soul Silver"
        case .black: return "Black"
        case .black2: return "Black 2"
        case .white: return "White"
        case .white2: return "White 2"
        case .x: return "X"
        case .y: return "Y"
        case .sun: return "Sun"
        case .moon: return "Moon"
        case .ultraSun: return "Ultra Sun"
        case .ultraMoon: return "Ulra Moon"
        case .sword: return "Sword"
        case .shield: return "Shield"
        case .unbound: return "Unbound"
        }
    }

    
    var color: Color{
        switch self{
        case .red, .firered, .ruby, .omegaRuby: return Color.red
        case .blue, .sapphire, .alphaSapphire: return Color.blue
        case .yellow: return Color.yellow
        case .gold: return Color.orange
        case .silver: return Color.gray
        case .crystal: return Color.cyan
        case .emerald, .leafgreen: return Color.green
        case .diamond: return Color.blue.opacity(0.8)
        case .pearl: return Color.pink
        case .platinum: return Color.gray.opacity(0.7)
        case .heartgold: return Color.yellow
        case .soulsilver: return Color.gray.opacity(0.7)
        case .black, .black2: return Color.black
        case .white, .white2: return Color.white.opacity(0.8)
        case .x: return Color.blue
        case .y: return Color.red
        case .sun: return Color.orange.opacity(0.8)
        case .moon: return Color.indigo.opacity(0.8)
        case .ultraSun: return Color.orange
        case .ultraMoon: return Color.indigo
        case .sword: return Color.cyan
        case .shield: return Color.red.opacity(0.7)
        default: return Color.gray
        }
    }
    
    var generation: Int{
        switch self{
        case .red, .blue, .yellow: return 1
        case .gold, .silver, .crystal: return 2
        case .ruby, .sapphire, .emerald, .firered, .leafgreen: return 3
        case .diamond, .pearl, .platinum, .heartgold, .soulsilver: return 4
        case .black, .white, .black2, .white2: return 5
        case .x, .y, .omegaRuby, .alphaSapphire: return 6
        case .sun, .moon, .ultraSun, .ultraMoon: return 7
        case .sword, .shield: return 8
        case .unbound: return 0
        }
    }
}



struct PokemonCaptureView: View {
    @EnvironmentObject var vm: ViewModel
    @EnvironmentObject var captureManager: CaptureManager
    
    let pokemon: Pokemon
    
    @State private var showGameSelection = false
    
    private var capturedGames: Set<PokemonGame>{
        captureManager.getCapturedGames(for: pokemon.name)
    }
    
    // A Pokemon can be caught only from its introduction generation
    private var introductionGeneration: Int{
        let pokemonId = vm.extractIDFromURL(pokemon.url)
        switch pokemonId{
        case 1...151: return 1
        case 52...251: return 2
        case 252...386: return 3
        case 387...494: return 4
        case 495...649: return 5
        case 650...721: return 6
        case 722...809: return 7
        case 810...905: return 8
        default: return 1
        }
    }
    
    private var availableGames: [PokemonGame]{

        let core = PokemonGame.allCases.filter { $0.generation >= introductionGeneration }
        let fan = PokemonGame.allCases.filter { $0.generation == 0 }
        // to display fan games
        let merged = fan + core
        
        // to avoid duplicatas
        var seen = Set<String>()
        let unique = merged.filter { game in
            if seen.contains(game.rawValue) { return false }
            seen.insert(game.rawValue)
            return true
        }
        // sort by generation so Fan Games appears first
        return unique.sorted { left, right in
            if left.generation != right.generation { return left.generation < right.generation }
            return left.displayName < right.displayName
        }
    }
    
    var body: some View {
        ScrollView{
            VStack(spacing:20){
                PokemonView(pokemon: pokemon)
                    .padding(.top,20)
                
                HStack{
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Available since Generation \(introductionGeneration)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing:12){
                    Text("Capture Status")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 30){
                        StatCard(
                            label: "Caught in",
                             color: .green,
                             value: "\(capturedGames.count)",
                             icon: "checkmark.circle.fill"
                        )
                        
                        StatCard(
                            label: "Total Games",
                            color: .blue,
                            value: "\(availableGames.count)",
                            icon: "gamecontroller.fill"
                        )
                    }
                }
                .padding()
                
                Button(action:{
                    showGameSelection = true
                }){
                    HStack{
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Register a Capture")
                            .font(.headline)
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // List current captured
                if !capturedGames.isEmpty{
                    VStack(alignment: .leading, spacing: 12){
                        Text("Caught in:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10){
                            ForEach(Array(capturedGames).sorted(by: {$0.generation < $1.generation}), id: \.id){ game in
                                CapturedGameBadge(
                                    game: game,
                                    onRemove: {
                                        captureManager.markAsNotCaught(pokemon.name, in: game)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                } else{
                    VStack(spacing: 10){
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("Not caught yet")
                            .foregroundStyle(.secondary)
                        Text("Tap the button above to capture")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showGameSelection){
            GameSelectionSheet(
                pokemonName: pokemon.name,
                captureManager: captureManager,
                availableGames: availableGames,
                introductionGeneration: introductionGeneration
            )
        }
        .environmentObject(captureManager)
    }
}


// To manage the local save of captures
@MainActor
class CaptureManager: ObservableObject{
    @Published var captures: [String: Set<PokemonGame>] = [:]
    
    private let captureKey = "pokemon_captures"
    
    // Path to save captures states on a JSON
    private var capturesFileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else{
            return nil
        }
        return documentsDirectory.appendingPathComponent("pokemon_captures.json")
    }
    
    
    init(){
        loadCaptures()
    }
    
    func loadCaptures(){
        if let fileURL = capturesFileURL,
           FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data){
            captures = decoded.mapValues{ gameStrings in
                Set(gameStrings.compactMap{ PokemonGame(rawValue: $0) })
            }
            print("Captures loaded from JSON")
            print("File location: \(fileURL.path)")
            return
        }
        
        // In case, fallback on UserDefaults, then migrate to JSON
        if let data = UserDefaults.standard.data(forKey: captureKey),
            let decoded = try? JSONDecoder().decode([String: [String]].self, from: data){
            captures = decoded.mapValues { gameStrings in
                Set(gameStrings.compactMap { PokemonGame(rawValue: $0) })
            }
            
            saveCaptures()
            print("Captures loaded from UserDefaults and migrated")
        }
    }
    
    func saveCaptures() {
        let encodable = captures.mapValues { games in
            games.map { $0.rawValue }
        }
        
        guard let encoded = try? JSONEncoder().encode(encodable) else {
            print("Failed to encode captures")
            return
        }
        
        if let fileURL = capturesFileURL{
            do{
                try encoded.write(to:fileURL, options: .atomic)
            } catch{
                print("Error saving to JSON= \(error)")
            }
        }
        UserDefaults.standard.set(encoded, forKey: captureKey)
        
    }
    
    func isCaught(_ pokemonName: String, in game: PokemonGame) -> Bool {
        return captures[pokemonName]?.contains(game) ?? false
    }
    
    func markAsCaught(_ pokemonName: String, in game: PokemonGame){
        if captures[pokemonName] == nil {
            captures[pokemonName] = Set<PokemonGame>()
        }
        captures[pokemonName]?.insert(game)
        saveCaptures()
    }
    
    func markAsNotCaught(_ pokemonName: String, in game: PokemonGame) {
        captures[pokemonName]?.remove(game)
        if captures[pokemonName]?.isEmpty == true {
            captures[pokemonName] = nil
        }
        saveCaptures()
    }
    
    func getCapturedGames(for pokemonName: String) -> Set<PokemonGame> {
        return captures[pokemonName] ?? []
    }
    
    func totalCaught(in game: PokemonGame) -> Int {
        return captures.values.filter { $0.contains(game) }.count
    }
    
    func exportCaptures() -> URL? {
        return capturesFileURL
    }
}




struct GameSelectionSheet: View {
    let pokemonName: String
    @ObservedObject var captureManager: CaptureManager
    @Environment(\.dismiss) var dismiss
    let availableGames: [PokemonGame]
    let introductionGeneration: Int
    
    @State private var selectedGames: Set<PokemonGame> = []
    
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 20){
                    
                    // Generation filter display
                    VStack(alignment: .leading, spacing: 12){
                        Text("Select Games")
                            .font(.title2)
                            .fontWeight(.bold)
            
                        Text("Chose the games where the Pokémon was caught")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack{
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Available form Generation \(introductionGeneration)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 4)
                        
                    }
                    .padding(.horizontal)
                    
                    let displayGenerations: [Int] = {
                        var gens = Array(max(1, introductionGeneration)...8)
                        // If any available game belongs to generation 0 (Fan Games) and introductionGeneration <= 0, include 0 first
                        // We also include 0 if any availableGames contain generation 0, regardless, so Fan Games can be displayed when relevant
                        gens.insert(0, at: 0)
                        
                        return gens
                    }()
                    
                    ForEach(displayGenerations, id: \.self) { gen in
                        let gamesInGen = availableGames.filter { $0.generation == gen}
                        
                        if !gamesInGen.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(gen == 0 ? "Fan Games" : "Generation \(gen)")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10){
                                    ForEach(gamesInGen) { game in
                                        GameSelectionButton (
                                            game: game,
                                            isSelected: selectedGames.contains(game),
                                            action: {
                                                toggleGame(game)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Register captures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading){
                    Button("Cancel"){
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Save"){
                        saveCaptures()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedGames.isEmpty)
                }
            }
            .onAppear{
                selectedGames = captureManager.getCapturedGames(for: pokemonName)
            }
        }
    }
    
    private func toggleGame(_ game: PokemonGame) {
        if selectedGames.contains(game){
            selectedGames.remove(game)
        } else{
            selectedGames.insert(game)
        }
    }
    
    private func saveCaptures() {
        let currentCaptures = captureManager.getCapturedGames(for: pokemonName)
        for game in currentCaptures{
            if !selectedGames.contains(game){
                captureManager.markAsNotCaught(pokemonName, in: game)
            }
        }
        
        for game in selectedGames{
            captureManager.markAsCaught(pokemonName, in: game)
        }
    }
}


struct GameSelectionButton: View{
    let game: PokemonGame
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View{
        Button(action: action){
            HStack{
                Circle()
                    .fill(game.color)
                    .frame(width: 10, height: 10)
                
                Text(game.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
                
                if isSelected{
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? game.color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? game.color: Color.clear, lineWidth: 2)
            )
        }
    }
}


struct CapturedGameBadge: View{
    let game: PokemonGame
    let onRemove: () -> Void
    
    var body: some View{
        HStack{
            Circle()
                .fill(game.color)
                .frame(width: 10, height: 10)
            
            Text(game.displayName)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
            
            Spacer()
            
            Button(action: onRemove){
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .cornerRadius(10)
        .background(game.color.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(game.color, lineWidth:  1.5)
        )
    }
}

struct StatCard: View{
    let label: String
    let color: Color
    let value: String
    let icon: String
    
    var body: some View{
        VStack(spacing: 8){
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}


struct PokemonCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        PokemonCaptureView(pokemon: Pokemon.samplePokemon)
            .environmentObject(ViewModel())
    }
}

