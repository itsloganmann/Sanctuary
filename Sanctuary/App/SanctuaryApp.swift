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
    @State private var pendingWidgetPanic = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dependencies)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    if url.scheme == "sanctuary" && url.host == "widget-tap" {
                        Task {
                            do {
                                try await dependencies.activatePanicMode()
                            } catch {
                                // Optionally handle error (e.g., show alert)
                            }
                        }
                    }
                }
        }
    }
}
