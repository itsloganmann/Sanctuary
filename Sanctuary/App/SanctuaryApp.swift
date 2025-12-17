//
//  SanctuaryApp.swift
//  Sanctuary
//
//  Created for iOS 18+ with Swift 6
//

import SwiftUI

@main
struct SanctuaryApp: App {
    @State private var dependencies = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dependencies)
                .preferredColorScheme(.dark)
        }
    }
}
