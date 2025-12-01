//
//  Helpers.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 28/10/2025.
//

import Foundation
import UIKit




extension Bundle {
    
    func decode<T: Decodable>(file: String) -> T {

        guard let url = self.url(forResource: file, withExtension: "json", subdirectory: nil) else {
            fatalError("Could not find \(file).json in bundle")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load \(file).json from bundle")
        }
        
        let decoder = JSONDecoder()
        guard let loadedData = try? decoder.decode(T.self, from: data) else {
            fatalError("Could not decode \(file).json from bundle")
        }
        return loadedData
    }
    
    func decodeOptional<T: Decodable>(file: String) -> T? {
        // To help debugging
        guard let url = self.url(forResource: file, withExtension: "json", subdirectory: nil) else {
            print("File not found: \(file).json")
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            print("Could not load data from: \(file).json")
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    func image(file: String) -> UIImage? {
        guard let url = self.url(forResource: file, withExtension: "png", subdirectory: nil) else {
            print("Image not found: \(file).png")
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
