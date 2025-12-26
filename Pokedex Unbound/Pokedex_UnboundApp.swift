//
//  Pokedex_UnboundApp.swift
//  Pokedex Unbound
//
//  Created by Nassim Rihane on 27/10/2025.
//

import SwiftUI

@main
struct Pokedex_UnboundApp: App {
    @StateObject private var captureManager = CaptureManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(captureManager)
        }
    }
}
