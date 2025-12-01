//
//  PokemonView.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 06/11/2025.
//

import SwiftUI



struct PokemonView: View {
    @EnvironmentObject var vm: ViewModel
    let pokemon: Pokemon
    let dimensions: Double = 140
    
    var body: some View {
        VStack {
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
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.gray)
                }
            }
            
            Text("\(pokemon.name.capitalized)")
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .padding(.bottom, 20)
        }
    }
    
    func loadLocalSprite(for pokemon: Pokemon) -> UIImage? {

        let index = vm.getPokemonIndex(pokemon: pokemon)
        let formattedIndex = String(format: "%03d", index)
        let fileName = "\(formattedIndex)_\(pokemon.name.lowercased())"
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "png"),
           let imageData = try? Data(contentsOf: url),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        
        print("Sprite not found : \(fileName).png")  // For debug
        return nil
    }
    
}



struct PokemonView_Previews: PreviewProvider {
    static var previews: some View {
        PokemonView(pokemon: Pokemon.samplePokemon)
            .environmentObject(ViewModel())
    }
}

