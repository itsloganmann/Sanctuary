//
//  SanctuaryApp.swift
//  Sanctuary
//
//  A personal safety and consent management app.
//  Swift Student Challenge 2026 — Logan Mann
//

import SwiftUI

@main
struct SanctuaryApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}
